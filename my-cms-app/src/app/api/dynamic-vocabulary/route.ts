import { NextRequest, NextResponse } from 'next/server';
import {
  AiWordCategory,
  AiWordFallbackWord,
  getAiWordCategories,
  getAiWordFallbackWords,
  getAiWordFallbackWordsByDifficulty,
  getAiWordSettings,
  isBlockedWord,
} from '@/lib/ai-word-game';
import { prisma } from '@/lib/prisma';
import { uploadToMinio } from '@/lib/minio';

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
  wordSource: 'gemini' | 'fallback';
  difficulty: 'easy' | 'medium' | 'hard';
};

type GeminiResponse = {
  candidates?: Array<{
    content?: {
      parts?: Array<{ text?: string }>;
    };
  }>;
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

async function getGeminiErrorMessage(response: Response) {
  const errorText = await response.text().catch(() => '');
  console.error('Gemini API error:', response.status, errorText);

  if (response.status === 429) {
    if (errorText.includes('PerDay') || errorText.includes('daily requests') || errorText.includes('quota exceeded')) {
      return 'Gemini quota exhausted (\u0e42\u0e04\u0e27\u0e15\u0e49\u0e32\u0e2b\u0e21\u0e14). Please wait for quota reset or check API billing.';
    }
    return 'Gemini rate limit or temporary quota reached (\u0e42\u0e04\u0e27\u0e15\u0e49\u0e32\u0e2b\u0e21\u0e14). Please try again later.';
  }

  if (response.status === 403) return 'GEMINI_API_KEY is not allowed to use this model.';
  if (response.status === 400) return 'Gemini request is invalid. Please check the model or prompt.';
  return `Gemini request failed (HTTP ${response.status})`;
}
async function generateWord(
  category: AiWordCategory,
  difficulty: 'easy' | 'medium' | 'hard',
) {
  const settings = await getAiWordSettings();
  const apiKey = process.env.GEMINI_API_KEY || process.env.GOOGLE_GENERATIVE_AI_API_KEY;
  const geminiModel = process.env.GEMINI_MODEL;
  if (!settings.useGemini) {
    throw new Error('Gemini vocabulary generation is disabled in AI Word Game settings.');
  }
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY is missing from env.');
  }
  if (!geminiModel) {
    throw new Error('GEMINI_MODEL is missing from env.');
  }

  const existingWords = await getAiWordFallbackWords(category.id);
  const excludeList = existingWords.map((w) => w.word.trim()).join(', ');

  const prompt = settings.promptTemplate
    .replaceAll('{{category}}', category.label)
    .replaceAll('{{thaiLabel}}', category.thaiLabel || category.label)
    .replaceAll('{{categorySlug}}', category.slug)
    .replaceAll('{{difficulty}}', difficulty)
    .replaceAll('{{excludeList}}', excludeList || 'none');

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        generationConfig: {
          responseMimeType: 'application/json',
          temperature: 0.9,
          maxOutputTokens: 140,
        },
      }),
    },
  );

  if (!response.ok) {
    const error = new Error(await getGeminiErrorMessage(response)) as Error & { status?: number };
    error.status = response.status;
    throw error;
  }

  const data = (await response.json()) as GeminiResponse;
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
  const parsed = extractJson(text);
  const word = parsed?.word ? String(parsed.word).trim() : '';
  if (!word) throw new Error('Gemini did not return a vocabulary word.');
  if (await isBlockedWord(word)) throw new Error(`Gemini returned a blocked word: ${word}`);

  return {
    word,
    category: category.slug,
    thaiMeaning: parsed?.thaiMeaning ? String(parsed.thaiMeaning).trim() : undefined,
    phonetic: parsed?.phonetic ? String(parsed.phonetic).trim() : undefined,
    imageUrl: undefined,
    wordSource: 'gemini' as const,
    difficulty,
  };
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
        { error: 'AI Word Game is disabled.' },
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

    // 2. Try Gemini if enabled — wrap in try/catch so a failure just skips Gemini
    let geminiPayload: VocabularyPayload | null = null;
    if (settings.useGemini) {
      try {
        const generated = await generateWord(category, difficulty);
        const query = `${generated.word} ${settings.imageQuerySuffix}`.trim();
        const image = generated.imageUrl
          ? { imageUrl: undefined, imageSource: undefined }
          : await fetchImage(generated.word);
        geminiPayload = {
          ...generated,
          query,
          imageUrl: generated.imageUrl ?? image.imageUrl,
          imageSource: generated.imageUrl ? 'admin' : image.imageSource,
        };
      } catch (geminiErr) {
        console.warn('Gemini word generation failed, using DB fallback only:', geminiErr);
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
    for (const p of geminiPayload ? [geminiPayload, ...dbPayloads] : dbPayloads) {
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
    if (geminiPayload) {
      await writeLog({ category, item: geminiPayload, status: 'success' });
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
