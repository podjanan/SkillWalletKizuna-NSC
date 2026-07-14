import { NextRequest, NextResponse } from 'next/server';
import {
  AiWordCategory,
  ensureAiWordGameDefaults,
  getAiWordCategories,
  getAiWordFallbackWords,
  getAiWordSettings,
  getBlockedTerms,
  isBlockedWord,
  callOllama,
} from '@/lib/ai-word-game';
import { prisma } from '@/lib/prisma';
import { uploadToMinio } from '@/lib/minio';
import { fallbackMetadata, getLocalDictEntry, getCandidates } from '@/lib/ai-word-dictionary';

type AdminAction =
  | 'createCategory'
  | 'updateCategory'
  | 'deleteCategory'
  | 'createWord'
  | 'updateWord'
  | 'deleteWord'
  | 'suggestWord'
  | 'previewWord'
  | 'refreshImage'
  | 'uploadImage'
  | 'createBlockedTerm'
  | 'updateBlockedTerm'
  | 'deleteBlockedTerm';

function cleanSlug(value: string) {
  return value.trim().toLowerCase().replace(/[^a-z0-9_-]+/g, '-').replace(/^-|-$/g, '');
}

function toBool(value: unknown, fallback = true) {
  return typeof value === 'boolean' ? value : fallback;
}

function toDifficulty(value: unknown): 'easy' | 'medium' | 'hard' {
  return value === 'medium' || value === 'hard' ? value : 'easy';
}

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


function simplePhonetic(word: string) {
  return word
    .trim()
    .replace(/([a-z])([A-Z])/g, '$1-$2')
    .replace(/\s+/g, '-')
    .toUpperCase();
}

function getFallbackMetadata(word: string) {
  const key = word.trim().toLowerCase();
  return fallbackMetadata[key] ?? {
    thaiMeaning: '',
    phonetic: simplePhonetic(word),
  };
}

async function getCategoryById(categoryId: string) {
  const categories = await getAiWordCategories();
  return categories.find((category) => category.id === categoryId) ?? categories[0];
}

async function generateSuggestion(
  category: AiWordCategory,
  difficulty: 'easy' | 'medium' | 'hard',
  excludeWords: string[] = []
) {
  const settings = await getAiWordSettings();
  if (!settings.useGemini) {
    throw new Error('AI suggestion is disabled in Voice Quest settings.');
  }

  // Fetch existing words to exclude them from suggestions
  const existingWords = await getAiWordFallbackWords(category.id);
  const existingWordSet = new Set([
    ...existingWords.map((w) => w.word.trim().toLowerCase()),
    ...excludeWords.map((w) => w.trim().toLowerCase())
  ]);

  let lastError = '';

  const candidates = getCandidates(category.slug, difficulty);
  const availableCandidates = candidates.filter(c => !existingWordSet.has(c.toLowerCase()));
  const useCandidates = availableCandidates.length > 0;

  const candidateConstraint = useCandidates
    ? `Choose exactly one English word from this Candidates list: ${availableCandidates.join(', ')}`
    : `Generate exactly one simple English vocabulary word for kids ages 4-9 (preschool to Grade 3/ป.3 maximum).`;

  for (let attempts = 0; attempts < 4; attempts++) {
    const excludeListStr = Array.from(existingWordSet).map(w => `- ${w}`).join('\n');
    const prompt = `You are an expert children's English vocabulary teacher.
The word MUST belong STRICTLY and directly to the category: ${category.label} (Thai concept: ${category.thaiLabel || ''}).
Selected difficulty: ${difficulty}.

Category Guidelines:
- Animals (สัตว์): Must be a direct animal species (e.g., cat, dog, elephant, rabbit, turtle, dolphin, bee). Do NOT suggest food, vehicles, or places.
- Food (อาหาร): Must be a direct edible food, fruit, vegetable, snack, or drink (e.g., apple, banana, cookie, bread, carrot, pizza, milk). Do NOT suggest animals or tools.
- Vehicles (ยานพาหนะ): Must be a direct mode of transport (e.g., car, train, rocket, bicycle, boat, plane, tractor). Do NOT suggest roads, places, or jobs.
- Nature (ธรรมชาติ): Must be a direct nature element, plant, flower, weather, or celestial body (e.g., tree, flower, rainbow, star, mountain, cloud, rain, sun). Do NOT suggest man-made items.

CRITICAL CONSTRAINTS:
1. ${candidateConstraint}
2. The word MUST NOT be in this list of already existing words (case-insensitive):
${excludeListStr || '- none'}
3. The word must be a simple, concrete noun that a young child under Grade 3 (ages 4-9) knows and can easily recognize. Avoid advanced or abstract words.
4. Difficulty guidance (strict character length):
   - easy: 3-5 letters (e.g. cat, dog, sun, pig, bird, fish)
   - medium: 5-7 letters (e.g. horse, tiger, carrot, melon, rocket, train, pencil)
   - hard: 7-10 letters max (e.g. elephant, penguin, mountain, rainbow, bicycle, notebook, umbrella)
5. The "thaiMeaning" MUST be the exact, correct Thai translation of the generated English word (e.g. if the word is "Kangaroo", the thaiMeaning must be "จิงโจ้", if the word is "Lion", the thaiMeaning must be "สิงโต"). Do NOT hallucinate, guess, or mismatch the translation.

Return the result in JSON format ONLY:
{
  "word": "EnglishWord",
  "thaiMeaning": "คำแปลภาษาไทยสั้นๆ ที่ถูกต้องตามหลักความเป็นจริงและเข้าใจง่ายสำหรับเด็ก",
  "phonetic": "คำสะกดเสียงพจนานุกรม เช่น AP-pul หรือ ZEE-bruh"
}`;

    const finalPrompt = prompt + `\n\n[System Attempt ID: ${attempts + 1} - Random seed: ${Math.floor(Math.random() * 1000)}]`;
    const currentTemp = 0.1 + attempts * 0.25; // 0.1, 0.35, 0.6, 0.85

    try {
      const text = await callOllama(finalPrompt, true, currentTemp);

      const parsed = extractJson(text);
      const word = parsed?.word ? String(parsed.word).trim() : '';
      const thaiMeaning = parsed?.thaiMeaning ? String(parsed.thaiMeaning).trim() : '';
      const phonetic = parsed?.phonetic ? String(parsed.phonetic).trim() : '';

      if (!word) {
        lastError = 'Ollama did not return a vocabulary word.';
        continue;
      }

      // 1. Check for duplicates in DB and active exclude list
      if (existingWordSet.has(word.toLowerCase())) {
        lastError = `AI returned a duplicate word: ${word}`;
        continue;
      }

      // 2. Check for blocked terms
      if (await isBlockedWord(word)) {
        existingWordSet.add(word.toLowerCase());
        lastError = `AI returned a blocked word: ${word}`;
        continue;
      }

      // 3. Programmatic length filter based on difficulty
      const wordLen = word.length;
      let isLengthValid = false;
      if (difficulty === 'easy' && wordLen >= 3 && wordLen <= 5) isLengthValid = true;
      else if (difficulty === 'medium' && wordLen >= 5 && wordLen <= 7) isLengthValid = true;
      else if (difficulty === 'hard' && wordLen >= 7 && wordLen <= 10) isLengthValid = true;

      if (!isLengthValid) {
        existingWordSet.add(word.toLowerCase());
        lastError = `AI returned "${word}" (length ${wordLen}) which does not match "${difficulty}" length constraint.`;
        continue;
      }

      const localEntry = getLocalDictEntry(word);
      return {
        word,
        thaiMeaning: localEntry ? localEntry.thaiMeaning : (thaiMeaning || getFallbackMetadata(word).thaiMeaning),
        phonetic: localEntry ? localEntry.phonetic : (phonetic || getFallbackMetadata(word).phonetic),
        source: localEntry ? 'local_dictionary' : 'ollama',
      };
    } catch (e) {
      lastError = e instanceof Error ? e.message : 'AI suggestion failed.';
      console.error('AI suggest exception:', e);
    }
  }

  // If we reach here, it means we exhausted all 4 attempts (usually because of duplicate/length constraint failures)
  // Let's fall back to a recycled candidate from our high-quality list!
  if (candidates.length > 0) {
    const randomIndex = Math.floor(Math.random() * candidates.length);
    const recycledWord = candidates[randomIndex];
    const dictEntry = getLocalDictEntry(recycledWord);
    if (dictEntry) {
      return {
        word: recycledWord,
        thaiMeaning: dictEntry.thaiMeaning,
        phonetic: dictEntry.phonetic,
        source: 'local_dictionary',
      };
    }
  }

  throw new Error(lastError || 'AI could not generate a vocabulary word matching constraints.');
}

async function enrichWord(word: string, category: AiWordCategory, difficulty: 'easy' | 'medium' | 'hard') {
  const localEntry = getLocalDictEntry(word);
  if (localEntry) {
    return {
      word: word.trim(),
      thaiMeaning: localEntry.thaiMeaning,
      phonetic: localEntry.phonetic,
      source: 'local_dictionary',
    };
  }

  const settings = await getAiWordSettings();
  const fallback = getFallbackMetadata(word);
  if (!settings.useGemini) {
    throw new Error('AI metadata generation is disabled in Voice Quest settings.');
  }

  const prompt = `You are a children's English vocabulary teacher. Create accurate metadata for the English word "${word}".
Word: "${word}"
Category: "${category.label}" (Thai concept: ${category.thaiLabel || ''})
Difficulty: "${difficulty}"

Instructions:
1. Translate the English word "${word}" into Thai accurately. The translation MUST be the correct, simple, and direct meaning of "${word}" in Thai suitable for children (e.g., "Kangaroo" translates to "จิงโจ้", "Cat" to "แมว", "Apple" to "แอปเปิล"). Do NOT hallucinate or make up a translation.
2. Provide a simple kid-friendly phonetic pronunciation guide in English syllables (e.g., "KAHN-guh-roo", "AP-pul").

Return ONLY valid JSON format:
{
  "word": "${word}",
  "thaiMeaning": "คำแปลภาษาไทยที่ถูกต้องและเข้าใจง่ายสั้นๆ",
  "phonetic": "simple English phonetic guide"
}`;

  const text = await callOllama(prompt, true);

  const parsed = extractJson(text);
  return {
    word: parsed?.word ? String(parsed.word).trim() : word,
    thaiMeaning: parsed?.thaiMeaning ? String(parsed.thaiMeaning).trim() : fallback.thaiMeaning,
    phonetic: parsed?.phonetic ? String(parsed.phonetic).trim() : fallback.phonetic,
    source: 'ollama',
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

async function fetchFallbackImage(word: string): Promise<{ url: string; error: string | null; source: string }> {
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
          return { url: minioUrl, error: null, source: 'duckduckgo' };
        }
      } catch (err) {
        console.error(`Failed to download DDG image ${img.image}:`, err);
      }
    }
  } catch (fallbackErr) {
    console.error('DuckDuckGo fallback failed:', fallbackErr);
  }

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
      return { url: minioUrl, error: null, source: 'robohash' };
    }
  } catch (roboErr) {
    console.error('RoboHash fallback failed:', roboErr);
  }

  return { url: '', error: 'Unable to fetch a fallback image.', source: '' };
}

async function fetchPreviewImage(word: string) {
  const query = `${word} cartoon clipart png`;
  const imageResult = await fetchFallbackImage(word);
  return {
    imageUrl: imageResult.url,
    imageSource: imageResult.source,
    query,
    error: imageResult.error,
  };
}

async function uploadManualImage(word: string, imageDataUrl: string) {
  const match = imageDataUrl.match(/^data:(image\/[a-zA-Z0-9.+-]+);base64,([\s\S]+)$/);
  if (!match) {
    throw new Error('Image must be uploaded as a base64 data URL.');
  }

  const contentType = match[1];
  const base64 = match[2];
  const buffer = Uint8Array.from(Buffer.from(base64, 'base64'));
  const extension = contentType.includes('jpeg') || contentType.includes('jpg')
    ? 'jpg'
    : contentType.includes('webp')
      ? 'webp'
      : contentType.includes('gif')
        ? 'gif'
        : 'png';
  const cleanWord = (word || 'manual')
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9_-]/g, '_')
    .replace(/^_+|_+$/g, '') || 'manual';
  const key = `ai-word-game/manual/${cleanWord}-${Date.now()}.${extension}`;
  const imageUrl = await uploadToMinio(key, buffer, contentType);

  return {
    imageUrl,
    imageSource: 'manual_upload',
  };
}

async function getLogs() {
  return prisma.$queryRaw`
    SELECT id, category_slug AS "categorySlug", word, thai_meaning AS "thaiMeaning",
           phonetic, query, image_url AS "imageUrl", image_source AS "imageSource",
           word_source AS "wordSource", status, error, created_at AS "createdAt"
    FROM ai_word_generation_log
    ORDER BY created_at DESC
    LIMIT 80
  `;
}

export async function GET() {
  await ensureAiWordGameDefaults();
  const [settings, categories, words, blockedTerms, logs] = await Promise.all([
    getAiWordSettings(),
    getAiWordCategories(),
    getAiWordFallbackWords(),
    getBlockedTerms(),
    getLogs(),
  ]);

  return NextResponse.json({
    settings,
    categories,
    words,
    blockedTerms,
    logs,
  });
}

export async function PATCH(request: NextRequest) {
  const body = await request.json();
  await ensureAiWordGameDefaults();

  await prisma.$executeRaw`
    UPDATE ai_word_game_settings
    SET enabled = ${toBool(body.enabled)},
        show_in_app = ${toBool(body.showInApp)},
        title = ${String(body.title ?? 'Voice Quest')},
        description = ${String(body.description ?? '')},
        cover_image_url = ${String(body.coverImageUrl ?? 'asset:assets/images/voice_quest_cover.png')},
        max_score = ${Number(body.maxScore ?? 100)},
        use_gemini = ${toBool(body.useGemini)},
        use_pixabay = ${toBool(body.usePixabay)},
        use_pexels = ${toBool(body.usePexels)},
        image_provider_order = ${String(body.imageProviderOrder ?? 'pixabay,pexels')},
        prompt_template = ${String(body.promptTemplate ?? '')},
        image_query_suffix = ${String(body.imageQuerySuffix ?? 'cartoon illustration for kids')},
        words_per_session_easy = ${Number(body.wordsPerSessionEasy ?? 3)},
        words_per_session_medium = ${Number(body.wordsPerSessionMedium ?? 5)},
        words_per_session_hard = ${Number(body.wordsPerSessionHard ?? 7)},
        time_limit_minutes = ${Number(body.timeLimitMinutes ?? 10)},
        enable_safe_search = ${toBool(body.enableSafeSearch)},
        updated_at = CURRENT_TIMESTAMP
    WHERE id = 'default'
  `;

  return NextResponse.json({ success: true });
}

export async function POST(request: NextRequest) {
  const body = await request.json();
  const action = body.action as AdminAction;

  if (action === 'createCategory') {
    const label = String(body.label ?? '').trim();
    if (!label) return NextResponse.json({ error: 'Label is required' }, { status: 400 });
    const slug = cleanSlug(String(body.slug || label || 'category'));
    if (!slug) return NextResponse.json({ error: 'Slug is required' }, { status: 400 });
    
    // Auto-pick color
    const colors = ['#66BB6A', '#FF9800', '#0D92F4', '#1AAA88', '#AB47BC', '#EC407A', '#26A69A', '#78909C'];
    const randomColor = colors[Math.floor(Math.random() * colors.length)];
    const color = body.color ? String(body.color) : randomColor;
    
    // Auto-pick icon
    const iconMap: Record<string, string> = {
      animals: '🦁',
      food: '🍎',
      vehicles: '🚀',
      nature: '🌈',
      bedroom: '🛏️',
      school: '📚',
      classroom: '📚',
    };
    const defaultIcon = iconMap[slug] ?? '✨';
    const icon = body.icon ? String(body.icon) : defaultIcon;
    
    // Query max sort order
    const maxSortRow = await prisma.$queryRaw<Array<{ max_order: number | null }>>`
      SELECT MAX(sort_order) as max_order FROM ai_word_category
    `;
    const nextSortOrder = (maxSortRow?.[0]?.max_order ?? -1) + 1;
    const sortOrder = body.sortOrder !== undefined ? Number(body.sortOrder) : nextSortOrder;
    
    await prisma.$executeRaw`
      INSERT INTO ai_word_category
        (id, slug, label, thai_label, icon, color, active, sort_order, updated_at)
      VALUES
        (${crypto.randomUUID()}, ${slug}, ${label},
         ${body.thaiLabel ? String(body.thaiLabel) : null},
         ${icon}, ${color},
         ${toBool(body.active)}, ${sortOrder}, CURRENT_TIMESTAMP)
    `;
  } else if (action === 'updateCategory') {
    await prisma.$executeRaw`
      UPDATE ai_word_category
      SET slug = ${cleanSlug(String(body.slug ?? ''))},
          label = ${String(body.label ?? '')},
          thai_label = ${body.thaiLabel ? String(body.thaiLabel) : null},
          icon = ${body.icon ? String(body.icon) : null},
          color = ${body.color ? String(body.color) : null},
          active = ${toBool(body.active)},
          sort_order = ${Number(body.sortOrder ?? 0)},
          updated_at = CURRENT_TIMESTAMP
      WHERE id = ${String(body.id)}
    `;
  } else if (action === 'deleteCategory') {
    await prisma.$executeRaw`
      DELETE FROM ai_word_category WHERE id = ${String(body.id)}
    `;
  } else if (action === 'createWord') {
    const wordClean = String(body.word ?? '').trim();
    const categoryId = String(body.categoryId);
    const existing = await prisma.$queryRaw<Array<{ id: string }>>`
      SELECT id FROM ai_word_fallback_word 
      WHERE category_id = ${categoryId} AND LOWER(word) = ${wordClean.toLowerCase()}
    `;

    if (existing.length > 0) {
      await prisma.$executeRaw`
        UPDATE ai_word_fallback_word
        SET thai_meaning = ${body.thaiMeaning ? String(body.thaiMeaning) : null},
            phonetic = ${body.phonetic ? String(body.phonetic) : null},
            image_url = ${body.imageUrl ? String(body.imageUrl) : null},
            difficulty = ${toDifficulty(body.difficulty)},
            active = ${toBool(body.active)},
            updated_at = CURRENT_TIMESTAMP
        WHERE id = ${existing[0].id}
      `;
    } else {
      await prisma.$executeRaw`
        INSERT INTO ai_word_fallback_word
          (id, category_id, word, thai_meaning, phonetic, image_url, difficulty, active, updated_at)
        VALUES
          (${crypto.randomUUID()}, ${categoryId}, ${wordClean},
           ${body.thaiMeaning ? String(body.thaiMeaning) : null},
           ${body.phonetic ? String(body.phonetic) : null},
           ${body.imageUrl ? String(body.imageUrl) : null},
           ${toDifficulty(body.difficulty)},
           ${toBool(body.active)}, CURRENT_TIMESTAMP)
      `;
    }
  } else if (action === 'updateWord') {
    await prisma.$executeRaw`
      UPDATE ai_word_fallback_word
      SET category_id = ${String(body.categoryId)},
          word = ${String(body.word ?? '')},
          thai_meaning = ${body.thaiMeaning ? String(body.thaiMeaning) : null},
          phonetic = ${body.phonetic ? String(body.phonetic) : null},
          image_url = ${body.imageUrl ? String(body.imageUrl) : null},
          difficulty = ${toDifficulty(body.difficulty)},
          active = ${toBool(body.active)},
          updated_at = CURRENT_TIMESTAMP
      WHERE id = ${String(body.id)}
    `;
  } else if (action === 'deleteWord') {
    await prisma.$executeRaw`
      DELETE FROM ai_word_fallback_word WHERE id = ${String(body.id)}
    `;
  } else if (action === 'suggestWord') {
    const category = await getCategoryById(String(body.categoryId ?? ''));
    if (!category) return NextResponse.json({ error: 'Category is required' }, { status: 400 });
    const difficulty = toDifficulty(body.difficulty);
    const exclude = Array.isArray(body.exclude) ? body.exclude.map(String) : [];
    try {
      const suggestion = await generateSuggestion(category, difficulty, exclude);
      const imageInfo = await fetchPreviewImage(suggestion.word);
      return NextResponse.json({
        word: suggestion.word,
        thaiMeaning: suggestion.thaiMeaning,
        phonetic: suggestion.phonetic,
        imageUrl: imageInfo.imageUrl,
        imageSource: imageInfo.imageSource,
        query: imageInfo.query,
        imageError: imageInfo.error,
        source: suggestion.source,
      });
    } catch (e) {
      const message = e instanceof Error ? e.message : 'Ollama suggestion failed.';
      const status = e instanceof Error && 'status' in e && e.status === 429 ? 429 : 502;
      return NextResponse.json({ error: message, source: 'ollama' }, { status });
    }
  } else if (action === 'previewWord') {
    const category = await getCategoryById(String(body.categoryId ?? ''));
    const word = String(body.word ?? '').trim();
    if (!category || !word) return NextResponse.json({ error: 'Category and word are required' }, { status: 400 });
    try {
      const [metadata, image] = await Promise.all([
        enrichWord(word, category, toDifficulty(body.difficulty)),
        fetchPreviewImage(word),
      ]);
      return NextResponse.json({
        ...metadata,
        ...image,
        imageError: image.error,
        difficulty: toDifficulty(body.difficulty),
      });
    } catch (e) {
      const message = e instanceof Error ? e.message : 'Ollama metadata generation failed.';
      const status = e instanceof Error && 'status' in e && e.status === 429 ? 429 : 502;
      return NextResponse.json({ error: message, source: 'ollama' }, { status });
    }
  } else if (action === 'refreshImage') {
    const word = String(body.word ?? '').trim();
    if (!word) return NextResponse.json({ error: 'Word is required' }, { status: 400 });
    const imageInfo = await fetchPreviewImage(word);
    return NextResponse.json({
      ...imageInfo,
      imageError: imageInfo.error,
    });
  } else if (action === 'uploadImage') {
    const word = String(body.word ?? '').trim();
    const imageDataUrl = String(body.imageDataUrl ?? '');
    if (!imageDataUrl) return NextResponse.json({ error: 'Image file is required' }, { status: 400 });
    const imageInfo = await uploadManualImage(word, imageDataUrl);
    return NextResponse.json(imageInfo);
  } else if (action === 'createBlockedTerm') {
    await prisma.$executeRaw`
      INSERT INTO ai_word_blocked_term (id, term, active)
      VALUES (${crypto.randomUUID()}, ${String(body.term ?? '').trim()}, ${toBool(body.active)})
    `;
  } else if (action === 'updateBlockedTerm') {
    await prisma.$executeRaw`
      UPDATE ai_word_blocked_term
      SET term = ${String(body.term ?? '').trim()},
          active = ${toBool(body.active)}
      WHERE id = ${String(body.id)}
    `;
  } else if (action === 'deleteBlockedTerm') {
    await prisma.$executeRaw`
      DELETE FROM ai_word_blocked_term WHERE id = ${String(body.id)}
    `;
  } else {
    return NextResponse.json({ error: 'Unknown action' }, { status: 400 });
  }

  return NextResponse.json({ success: true });
}
