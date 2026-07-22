import { NextRequest, NextResponse } from 'next/server';
import {
  AiWordCategory,
  AiWordFallbackWord,
  getAiWordCategories,
  getAiWordFallbackWords,
  getAiWordFallbackWordsByDifficulty,
  getAiWordSettings,
  isBlockedWord,
  callOllama,
} from '@/lib/ai-word-game';
import { prisma } from '@/lib/prisma';
import { uploadToMinio } from '@/lib/minio';
import { getLocalDictEntry, getCandidates } from '@/lib/ai-word-dictionary';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-API-Key, x-requested-with',
  'Access-Control-Max-Age': '86400',
};

type VocabularyPayload = {
  word: string;
  category: string;
  thaiMeaning?: string;
  phonetic?: string;
  imageUrl?: string;
  imageSource?: string;
  query: string;
  wordSource: 'ollama' | 'local_dictionary' | 'fallback';
  difficulty: 'easy' | 'medium' | 'hard';
};

function extractJson(text: string): Record<string, unknown> | null {
  try {
    return JSON.parse(text);
  } catch {
    const match = text.match(/\{[\s\S]*\}/);
    if (!match) return null;
    try {
      return JSON.parse(match[0]);
    } catch {
      return null;
    }
  }
}

async function resolveCategory(rawCategory: unknown) {
  const requested = String(rawCategory || '').trim().toLowerCase();
  const categories = await getAiWordCategories({ activeOnly: true });
  return (
    categories.find((category) => category.slug.toLowerCase() === requested) ??
    categories[0]
  );
}

function toDifficulty(value: unknown): 'easy' | 'medium' | 'hard' {
  return value === 'medium' || value === 'hard' ? value : 'easy';
}

function getSessionCount(
  settings: Awaited<ReturnType<typeof getAiWordSettings>>,
  difficulty: 'easy' | 'medium' | 'hard',
) {
  if (difficulty === 'hard') return settings.wordsPerSessionHard;
  if (difficulty === 'medium') return settings.wordsPerSessionMedium;
  return settings.wordsPerSessionEasy;
}

async function generateWord(
  category: AiWordCategory,
  difficulty: 'easy' | 'medium' | 'hard',
) {
  const settings = await getAiWordSettings();
  if (!settings.useGemini) {
    throw new Error('AI vocabulary generation is disabled in Voice Quest settings.');
  }

  const existingWords = await getAiWordFallbackWords(category.id);
  const existingWordSet = new Set(existingWords.map((w) => w.word.trim().toLowerCase()));

  let lastError = '';

  const candidates = getCandidates(category.slug, difficulty);
  const availableCandidates = candidates.filter(c => !existingWordSet.has(c.toLowerCase()));
  const useCandidates = availableCandidates.length > 0;

  const candidateConstraint = useCandidates
    ? `\n4. The word MUST be chosen from this Candidates list: ${availableCandidates.join(', ')}`
    : '';

  for (let attempts = 0; attempts < 4; attempts++) {
    const excludeListStr = Array.from(existingWordSet).map(w => `- ${w}`).join('\n');
    
    // Append strict overrides for local model behavior (children under Grade 3 / ป.3, length constraint)
    const basePrompt = settings.promptTemplate
      .replaceAll('{{category}}', category.label)
      .replaceAll('{{thaiLabel}}', category.thaiLabel || category.label)
      .replaceAll('{{categorySlug}}', category.slug)
      .replaceAll('{{difficulty}}', difficulty)
      .replaceAll('{{excludeList}}', excludeListStr || '- none');

    const prompt = basePrompt 
      + `\n\nCRITICAL OVERRIDE CONSTRAINTS FOR CHILDREN (GRADE 3 / ป.3 MAXIMUM):`
      + `\n1. The word must be simple and easily understood by children ages 4-9 (preschool to Grade 3). Do NOT generate advanced or academic words.`
      + `\n2. The word MUST be strictly within character length for difficulty "${difficulty}":`
      + (difficulty === 'easy' ? '\n   - 3 to 5 characters (e.g. dog, cat, sun, bird, fish, apple)' : difficulty === 'medium' ? '\n   - 5 to 7 characters (e.g. horse, tiger, carrot, train, pencil)' : '\n   - 7 to 10 characters (e.g. elephant, penguin, rainbow, bicycle)')
      + `\n3. The "thaiMeaning" MUST be the exact, correct Thai translation of the English word (e.g. Kangaroo -> "จิงโจ้", Lion -> "สิงโต"). Do NOT guess or hallucinate.`
      + candidateConstraint;

    const finalPrompt = prompt + `\n\n[System Attempt ID: ${attempts + 1} - Random seed: ${Math.floor(Math.random() * 1000)}]`;
    const currentTemp = 0.1 + attempts * 0.25; // 0.1, 0.35, 0.6, 0.85

    try {
      let text = '';
      text = await callOllama(finalPrompt, true, currentTemp);

      const parsed = extractJson(text);
      const word = parsed?.word ? String(parsed.word).trim() : '';
      if (!word) {
        lastError = 'AI did not return a vocabulary word.';
        continue;
      }

      // Check duplicates
      if (existingWordSet.has(word.toLowerCase())) {
        lastError = `AI generated a duplicate word: ${word}`;
        continue;
      }

      // Check blocked terms
      if (await isBlockedWord(word)) {
        existingWordSet.add(word.toLowerCase());
        lastError = `AI returned a blocked word: ${word}`;
        continue;
      }

      // Check strict length
      const wordLen = word.length;
      let isLengthValid = false;
      if (difficulty === 'easy' && wordLen >= 3 && wordLen <= 5) isLengthValid = true;
      else if (difficulty === 'medium' && wordLen >= 5 && wordLen <= 7) isLengthValid = true;
      else if (difficulty === 'hard' && wordLen >= 7 && wordLen <= 10) isLengthValid = true;

      if (!isLengthValid) {
        existingWordSet.add(word.toLowerCase());
        lastError = `AI returned word "${word}" (length ${wordLen}) which does not match "${difficulty}" length constraint.`;
        continue;
      }

      const localEntry = getLocalDictEntry(word);

      return {
        word,
        category: category.slug,
        thaiMeaning: localEntry ? localEntry.thaiMeaning : (parsed?.thaiMeaning ? String(parsed.thaiMeaning).trim() : undefined),
        phonetic: localEntry ? localEntry.phonetic : (parsed?.phonetic ? String(parsed.phonetic).trim() : undefined),
        imageUrl: undefined,
        wordSource: localEntry ? ('local_dictionary' as const) : ('ollama' as const),
        difficulty,
      };
    } catch (err) {
      lastError = err instanceof Error ? err.message : 'AI word generation error.';
      console.error('AI word generation attempt failed:', err);
    }
  }

  // Fallback to recycled candidate if AI failed
  if (candidates.length > 0) {
    const randomIndex = Math.floor(Math.random() * candidates.length);
    const recycledWord = candidates[randomIndex];
    const dictEntry = getLocalDictEntry(recycledWord);
    if (dictEntry) {
      return {
        word: recycledWord,
        category: category.slug,
        thaiMeaning: dictEntry.thaiMeaning,
        phonetic: dictEntry.phonetic,
        imageUrl: undefined,
        wordSource: 'local_dictionary' as const,
        difficulty,
      };
    }
  }

  throw new Error(lastError || 'AI could not generate a valid vocabulary word matching children constraints.');
}
async function getDuckDuckGoImages(query: string) {
  try {
    const searchPageResponse = await fetch(
      `https://duckduckgo.com/?q=${encodeURIComponent(query)}`,
      {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        }
      }
    );
    if (!searchPageResponse.ok) return [];
    const html = await searchPageResponse.text();
    const vqdMatch = html.match(/vqd=['"]([^'"]+)['"]/);
    if (!vqdMatch) return [];
    const vqd = vqdMatch[1];

    const imageResponse = await fetch(
      `https://duckduckgo.com/i.js?l=us-en&o=json&q=${encodeURIComponent(query)}&vqd=${vqd}&f=,,,&p=1`,
      {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Referer': 'https://duckduckgo.com/'
        }
      }
    );
    if (!imageResponse.ok) return [];
    const data = await imageResponse.json();
    return data.results || [];
  } catch (e) {
    console.error('DuckDuckGo image search error:', e);
    return [];
  }
}

async function fetchFallbackImage(word: string): Promise<string | null> {
  try {
    console.log(`Fetching image from DuckDuckGo for word: "${word}"`);
    const ddgImages = await getDuckDuckGoImages(`${word} cartoon clipart png`);
    for (const img of ddgImages.slice(0, 5)) {
      try {
        const fetchRes = await fetch(img.image, {
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
          },
          signal: AbortSignal.timeout(5000)
        });
        if (fetchRes.ok) {
          const arrayBuffer = await fetchRes.arrayBuffer();
          const u8array = new Uint8Array(arrayBuffer);
          const cleanWord = word.trim().toLowerCase().replace(/[^a-z0-9_-]/g, '_');
          const contentType = fetchRes.headers.get('content-type') || 'image/png';
          const fileExt = contentType.includes('jpeg') || contentType.includes('jpg') ? 'jpg' : 'png';
          const key = `ai-word-game/${cleanWord}.${fileExt}`;
          const minioUrl = await uploadToMinio(key, u8array, contentType);
          return minioUrl;
        }
      } catch (err) {
        console.error(`Failed to download DDG image ${img.image}:`, err);
      }
    }
  } catch (fallbackErr) {
    console.error('DuckDuckGo fallback failed:', fallbackErr);
  }

  // Final fallback to RoboHash
  try {
    console.log(`DuckDuckGo fallback failed. Falling back to RoboHash for word: "${word}"`);
    const fallbackUrl = `https://robohash.org/${encodeURIComponent(word)}.png?set=set4`;
    const fetchRes = await fetch(fallbackUrl);
    if (fetchRes.ok) {
      const arrayBuffer = await fetchRes.arrayBuffer();
      const u8array = new Uint8Array(arrayBuffer);
      const cleanWord = word.trim().toLowerCase().replace(/[^a-z0-9_-]/g, '_');
      const key = `ai-word-game/${cleanWord}.jpg`;
      const minioUrl = await uploadToMinio(key, u8array, 'image/png');
      return minioUrl;
    }
  } catch (roboErr) {
    console.error('RoboHash fallback failed:', roboErr);
  }

  return null;
}

async function fetchImage(word: string) {
  const imageUrl = await fetchFallbackImage(word);
  return {
    imageUrl: imageUrl ?? undefined,
    imageSource: imageUrl ? 'web' : undefined,
  };
}

async function writeLog(payload: {
  category: AiWordCategory;
  item?: VocabularyPayload;
  status: 'success' | 'error';
  error?: string;
}) {
  await prisma.$executeRaw`
    INSERT INTO ai_word_generation_log
      (id, category_id, category_slug, word, thai_meaning, phonetic, query,
       image_url, image_source, word_source, status, error)
    VALUES
      (${crypto.randomUUID()}, ${payload.category.id}, ${payload.category.slug},
       ${payload.item?.word ?? null}, ${payload.item?.thaiMeaning ?? null},
       ${payload.item?.phonetic ?? null}, ${payload.item?.query ?? null},
       ${payload.item?.imageUrl ?? null}, ${payload.item?.imageSource ?? null},
       ${payload.item?.wordSource ?? null}, ${payload.status}, ${payload.error ?? null})
  `;
}

export async function GET() {
  const settings = await getAiWordSettings();
  const categories = await getAiWordCategories({ activeOnly: true });
  return NextResponse.json(
    {
      status: 'Dynamic Vocabulary Endpoint Ready',
      settings: {
        enabled: settings.enabled,
        showInApp: settings.showInApp,
        title: settings.title,
        maxScore: settings.maxScore,
        coverImageUrl: settings.coverImageUrl,
        timeLimitMinutes: settings.timeLimitMinutes,
      },
      categories,
    },
    { status: 200, headers: corsHeaders },
  );
}

export async function POST(request: NextRequest) {
  let category: AiWordCategory | undefined;
  try {
    const settings = await getAiWordSettings();
    if (!settings.enabled) {
      return NextResponse.json(
        { error: 'Voice Quest is disabled.' },
        { status: 403, headers: corsHeaders },
      );
    }

    const body = await request.json().catch(() => ({}));
    category = await resolveCategory(body?.category);
    const difficulty = toDifficulty(body?.difficulty);
    if (!category) {
      return NextResponse.json(
        { error: 'No active vocabulary categories.' },
        { status: 404, headers: corsHeaders },
      );
    }

    const requestedCount = Number(body?.count ?? 0);
    const count = Math.max(1, Math.min(20, requestedCount || getSessionCount(settings, difficulty)));
    const sessionMode = Boolean(body?.session || body?.count || body?.difficulty);

    // --- Strict difficulty-aware session building ---
    // 1. Always load DB fallback words filtered by category + difficulty
    const dbWords = await getAiWordFallbackWordsByDifficulty(category.id, difficulty);

    // 2. Try Gemini if enabled — wrap in try/catch and enforce a strict timeout to prevent client timeout
    // Session requests should start immediately from the curated DB pool.
    // AI generation and remote image lookup remain available for single-word
    // requests, but no longer block a player who presses Start Quest.
    let aiPayload: VocabularyPayload | null = null;
    if (settings.useGemini && !sessionMode) {
      try {
        const generatedPromise = (async () => {
          const generated = await generateWord(category, difficulty);
          
          let imageUrl: string | undefined = generated.imageUrl;
          let imageSource: string | undefined = generated.imageUrl ? 'admin' : undefined;
          
          if (!imageUrl) {
            try {
              // 3-second timeout limit for image fetch
              const imageResult = await Promise.race([
                fetchImage(generated.word),
                new Promise<{ imageUrl?: string; imageSource?: string }>((_, reject) => 
                  setTimeout(() => reject(new Error('Image fetch timeout')), 3000)
                )
              ]);
              imageUrl = imageResult.imageUrl;
              imageSource = imageResult.imageSource;
            } catch (imgErr) {
              console.warn('Image fetch timed out or failed:', imgErr);
            }
          }
          
          return {
            ...generated,
            query: `${generated.word} ${settings.imageQuerySuffix}`.trim(),
            imageUrl,
            imageSource: generated.imageUrl ? 'admin' : imageSource,
          };
        })();

        // 8-second strict timeout limit for the entire AI word generation
        aiPayload = await Promise.race([
          generatedPromise,
          new Promise<null>((_, reject) => 
            setTimeout(() => reject(new Error('AI generation timeout')), 8000)
          )
        ]);
      } catch (aiErr) {
        console.warn('AI word generation timed out or failed, using DB fallback only:', aiErr);
      }
    }

    // 3. Build the session item pool: Gemini word first (if any), then shuffled DB words
    const dbPayloads: VocabularyPayload[] = dbWords.map((w: AiWordFallbackWord) => ({
      word: w.word,
      category: category!.slug,
      thaiMeaning: w.thaiMeaning ?? undefined,
      phonetic: w.phonetic ?? undefined,
      imageUrl: w.imageUrl ?? undefined,
      imageSource: w.imageUrl ? 'admin' : undefined,
      query: `${w.word} ${settings.imageQuerySuffix}`.trim(),
      wordSource: 'fallback' as const,
      difficulty,
    }));

    // Shuffle DB pool
    for (let i = dbPayloads.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [dbPayloads[i], dbPayloads[j]] = [dbPayloads[j], dbPayloads[i]];
    }

    // Combine: Gemini word + DB words, deduplicate by word (case-insensitive)
    const seen = new Set<string>();
    const allPayloads: VocabularyPayload[] = [];
    for (const p of aiPayload ? [aiPayload, ...dbPayloads] : dbPayloads) {
      const key = p.word.trim().toLowerCase();
      if (!seen.has(key)) {
        seen.add(key);
        allPayloads.push(p);
      }
    }

    // 4. Return 404 when pool is empty
    if (allPayloads.length === 0) {
      return NextResponse.json(
        { error: 'ไม่มีศัพท์ในคลังสำหรับหมวดหมู่และระดับความยากนี้' },
        { status: 404, headers: corsHeaders },
      );
    }

    // 5. Slice to session count
    const sessionItems = allPayloads.slice(0, count);

    // Log only the Gemini-generated word if present
    if (aiPayload) {
      await writeLog({ category, item: aiPayload, status: 'success' });
    }

    if (sessionMode) {
      return NextResponse.json(
        {
          items: sessionItems,
          category,
          maxScore: settings.maxScore,
          settings: {
            title: settings.title,
            maxScore: settings.maxScore,
            coverImageUrl: settings.coverImageUrl,
            timeLimitMinutes: settings.timeLimitMinutes,
            wordsPerSession: count,
          },
        },
        { status: 200, headers: corsHeaders },
      );
    }
    return NextResponse.json(sessionItems[0], { status: 200, headers: corsHeaders });
  } catch (error: unknown) {
    console.error('Dynamic vocabulary error:', error);
    const message = error instanceof Error
      ? error.message
      : 'Cannot generate vocabulary item.';
    const status = error instanceof Error && 'status' in error && (error as Error & { status?: number }).status === 429 ? 429 : 500;
    if (category) {
      await writeLog({ category, status: 'error', error: message });
    }
    return NextResponse.json(
      { error: message },
      { status, headers: corsHeaders },
    );
  }
}

export async function OPTIONS() {
  return NextResponse.json({}, { headers: corsHeaders });
}
