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

function shuffle<T>(items: T[]) {
  return [...items].sort(() => Math.random() - 0.5);
}

function pickFallback(
  category: AiWordCategory,
  words: AiWordFallbackWord[],
  difficulty: 'easy' | 'medium' | 'hard',
) {
  if (words.length === 0) {
    return {
      word: 'Octopus',
      category: category.slug,
      thaiMeaning: 'ปลาหมึกยักษ์',
      phonetic: 'OK-tuh-pus',
      imageUrl: undefined,
      wordSource: 'fallback' as const,
      difficulty,
    };
  }
  const item = words[Math.floor(Math.random() * words.length)];
  return {
    word: item.word,
    category: category.slug,
    thaiMeaning: item.thaiMeaning ?? undefined,
    phonetic: item.phonetic ?? undefined,
    imageUrl: item.imageUrl ?? undefined,
    wordSource: 'fallback' as const,
    difficulty,
  };
}

async function uploadGeneratedImage(word: string, base64Bytes: string): Promise<string | null> {
  try {
    const buffer = Buffer.from(base64Bytes, 'base64');
    const u8array = new Uint8Array(buffer);
    const cleanWord = word.trim().toLowerCase().replace(/[^a-z0-9_-]/g, '_');
    const key = `ai-word-game/${cleanWord}.jpg`;
    const url = await uploadToMinio(key, u8array, 'image/jpeg');
    return url;
  } catch (e) {
    console.error('MinIO upload error:', e);
    return null;
  }
}

async function generateWord(
  category: AiWordCategory,
  fallbackWords: AiWordFallbackWord[],
  difficulty: 'easy' | 'medium' | 'hard',
) {
  const settings = await getAiWordSettings();
  const apiKey = process.env.GEMINI_API_KEY || process.env.GOOGLE_GENERATIVE_AI_API_KEY;
  if (!settings.useGemini || !apiKey) return pickFallback(category, fallbackWords, difficulty);

  // Fetch existing words to exclude them from dynamic suggestions
  const existingWords = await getAiWordFallbackWords(category.id);
  const excludeList = existingWords.map((w) => w.word.trim()).join(', ');

  const prompt = settings.promptTemplate
    .replaceAll('{{category}}', category.label)
    .replaceAll('{{thaiLabel}}', category.thaiLabel || category.label)
    .replaceAll('{{categorySlug}}', category.slug)
    .replaceAll('{{difficulty}}', difficulty)
    .replaceAll('{{excludeList}}', excludeList || 'none');

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${settings.geminiModel}:generateContent?key=${apiKey}`,
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
    console.error('Gemini vocabulary error:', response.status, await response.text());
    return pickFallback(category, fallbackWords, difficulty);
  }

  const data = (await response.json()) as GeminiResponse;
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
  const parsed = extractJson(text);
  const word = parsed?.word ? String(parsed.word).trim() : '';
  if (!word || await isBlockedWord(word)) return pickFallback(category, fallbackWords, difficulty);

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
    console.log(`Gemini quota limit hit. Falling back to DuckDuckGo for word: "${word}"`);
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

async function generateGeminiImage(word: string) {
  const apiKey = process.env.GEMINI_API_KEY || process.env.GOOGLE_GENERATIVE_AI_API_KEY;
  if (!apiKey) return null;
  try {
    const prompt = `A cute, colorful cartoon illustration of "${word}" on a plain solid white background, flat vector design, child-friendly, sticker style, simple shapes, 2D art, no text, no labels.`.trim();
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key=${apiKey}`;
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        generationConfig: {
          responseModalities: ["TEXT", "IMAGE"],
        },
      }),
    });
    if (!response.ok) {
      const status = response.status;
      const errorText = await response.text();
      console.error('Gemini Image Generation Error:', status, errorText);
      if (status === 429) {
        return await fetchFallbackImage(word);
      }
      return null;
    }
    const data = await response.json();
    const part = data?.candidates?.[0]?.content?.parts?.find((p: any) => p.inlineData || p.inline_data);
    const base64Bytes = part?.inlineData?.data || part?.inline_data?.data;
    if (base64Bytes) {
      const minioUrl = await uploadGeneratedImage(word, base64Bytes);
      return minioUrl;
    }
  } catch (e) {
    console.error('Gemini Image Generation Exception:', e);
  }
  return null;
}

async function fetchImage(word: string) {
  const imageUrl = await generateGeminiImage(word);
  return {
    imageUrl: imageUrl ?? undefined,
    imageSource: imageUrl ? 'gemini' : undefined,
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
        coverImageUrl: settings.coverImageUrl,
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
    const approvedWords = await getAiWordFallbackWordsByDifficulty(category.id, difficulty, true);

    if (sessionMode && approvedWords.length > 0) {
      const selectedWords = shuffle(approvedWords).slice(0, count);
      const items = selectedWords.map((word) => ({
        word: word.word,
        category: category?.slug ?? '',
        thaiMeaning: word.thaiMeaning ?? undefined,
        phonetic: word.phonetic ?? undefined,
        imageUrl: word.imageUrl ?? undefined,
        imageSource: word.imageUrl ? 'admin' : undefined,
        query: `${word.word} ${settings.imageQuerySuffix}`.trim(),
        wordSource: 'fallback' as const,
        difficulty,
      }));

      await Promise.all(items.map((item) => writeLog({ category: category!, item, status: 'success' })));
      return NextResponse.json(
        {
          items,
          category,
          settings: {
            title: settings.title,
            maxScore: settings.maxScore,
            wordsPerSession: count,
          },
        },
        { status: 200, headers: corsHeaders },
      );
    }

    const fallbackWords = await getAiWordFallbackWords(category.id, true);
    const generated = await generateWord(category, fallbackWords, difficulty);
    const query = `${generated.word} ${settings.imageQuerySuffix}`.trim();
    const image = generated.imageUrl
      ? { imageUrl: undefined, imageSource: undefined }
      : await fetchImage(generated.word);

    const payload: VocabularyPayload = {
      ...generated,
      query,
      imageUrl: generated.imageUrl ?? image.imageUrl,
      imageSource: generated.imageUrl ? 'admin' : image.imageSource,
    };

    await writeLog({ category, item: payload, status: 'success' });
    if (sessionMode) {
      return NextResponse.json(
        {
          items: [payload],
          category,
          settings: {
            title: settings.title,
            maxScore: settings.maxScore,
            wordsPerSession: count,
          },
        },
        { status: 200, headers: corsHeaders },
      );
    }
    return NextResponse.json(payload, { status: 200, headers: corsHeaders });
  } catch (error: unknown) {
    console.error('Dynamic vocabulary error:', error);
    const message = error instanceof Error
      ? error.message
      : 'Cannot generate vocabulary item.';
    if (category) {
      await writeLog({ category, status: 'error', error: message });
    }
    return NextResponse.json(
      { error: message },
      { status: 500, headers: corsHeaders },
    );
  }
}

export async function OPTIONS() {
  return NextResponse.json({}, { headers: corsHeaders });
}
