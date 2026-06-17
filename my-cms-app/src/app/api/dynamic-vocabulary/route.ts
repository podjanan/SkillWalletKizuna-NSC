import { NextRequest, NextResponse } from 'next/server';
import {
  AiWordCategory,
  AiWordFallbackWord,
  getAiWordCategories,
  getAiWordFallbackWords,
  getAiWordSettings,
  isBlockedWord,
} from '@/lib/ai-word-game';
import { prisma } from '@/lib/prisma';

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
};

type GeminiResponse = {
  candidates?: Array<{
    content?: {
      parts?: Array<{ text?: string }>;
    };
  }>;
};

type ImageSearchResult = {
  imageUrl?: string;
  imageSource?: string;
};

type PixabayHit = {
  webformatURL?: string;
};

type PexelsPhoto = {
  src?: {
    large?: string;
  };
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

function pickFallback(category: AiWordCategory, words: AiWordFallbackWord[]) {
  if (words.length === 0) {
    return {
      word: 'Octopus',
      category: category.slug,
      thaiMeaning: 'ปลาหมึกยักษ์',
      phonetic: 'OK-tuh-pus',
      wordSource: 'fallback' as const,
    };
  }
  const item = words[Math.floor(Math.random() * words.length)];
  return {
    word: item.word,
    category: category.slug,
    thaiMeaning: item.thaiMeaning ?? undefined,
    phonetic: item.phonetic ?? undefined,
    wordSource: 'fallback' as const,
  };
}

async function generateWord(category: AiWordCategory, fallbackWords: AiWordFallbackWord[]) {
  const settings = await getAiWordSettings();
  const apiKey = process.env.GEMINI_API_KEY || process.env.GOOGLE_GENERATIVE_AI_API_KEY;
  if (!settings.useGemini || !apiKey) return pickFallback(category, fallbackWords);

  const prompt = settings.promptTemplate
    .replaceAll('{{category}}', category.label)
    .replaceAll('{{categorySlug}}', category.slug);

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
          maxOutputTokens: 120,
        },
      }),
    },
  );

  if (!response.ok) {
    console.error('Gemini vocabulary error:', response.status, await response.text());
    return pickFallback(category, fallbackWords);
  }

  const data = (await response.json()) as GeminiResponse;
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
  const parsed = extractJson(text);
  const word = parsed?.word ? String(parsed.word).trim() : '';
  if (!word || await isBlockedWord(word)) return pickFallback(category, fallbackWords);

  return {
    word,
    category: category.slug,
    thaiMeaning: parsed?.thaiMeaning ? String(parsed.thaiMeaning).trim() : undefined,
    phonetic: parsed?.phonetic ? String(parsed.phonetic).trim() : undefined,
    wordSource: 'gemini' as const,
  };
}

async function fetchPixabayImage(query: string): Promise<ImageSearchResult> {
  const apiKey = process.env.PIXABAY_API_KEY;
  if (!apiKey) return {};

  const params = new URLSearchParams({
    key: apiKey,
    q: query,
    image_type: 'illustration',
    safesearch: 'true',
    per_page: '8',
    orientation: 'horizontal',
  });

  const response = await fetch(`https://pixabay.com/api/?${params.toString()}`);
  if (!response.ok) {
    console.error('Pixabay error:', response.status, await response.text());
    return {};
  }

  const data = (await response.json()) as { hits?: PixabayHit[] };
  const hit = data?.hits?.find((item) => item?.webformatURL) ?? data?.hits?.[0];
  return hit?.webformatURL
    ? { imageUrl: hit.webformatURL, imageSource: 'pixabay' }
    : {};
}

async function fetchPexelsImage(query: string): Promise<ImageSearchResult> {
  const apiKey = process.env.PEXELS_API_KEY;
  if (!apiKey) return {};

  const params = new URLSearchParams({
    query,
    per_page: '8',
    orientation: 'landscape',
  });

  const response = await fetch(`https://api.pexels.com/v1/search?${params.toString()}`, {
    headers: { Authorization: apiKey },
  });
  if (!response.ok) {
    console.error('Pexels error:', response.status, await response.text());
    return {};
  }

  const data = (await response.json()) as { photos?: PexelsPhoto[] };
  const photo = data?.photos?.find((item) => item?.src?.large) ?? data?.photos?.[0];
  return photo?.src?.large
    ? { imageUrl: photo.src.large, imageSource: 'pexels' }
    : {};
}

async function fetchImage(query: string) {
  const settings = await getAiWordSettings();
  const providers = settings.imageProviderOrder
    .split(',')
    .map((provider) => provider.trim().toLowerCase())
    .filter(Boolean);

  for (const provider of providers) {
    if (provider === 'pixabay' && settings.usePixabay) {
      const image = await fetchPixabayImage(query);
      if (image.imageUrl) return image;
    }
    if (provider === 'pexels' && settings.usePexels) {
      const image = await fetchPexelsImage(query);
      if (image.imageUrl) return image;
    }
  }
  return {};
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
    if (!category) {
      return NextResponse.json(
        { error: 'No active vocabulary categories.' },
        { status: 404, headers: corsHeaders },
      );
    }

    const fallbackWords = await getAiWordFallbackWords(category.id, true);
    const generated = await generateWord(category, fallbackWords);
    const query = `${generated.word} ${settings.imageQuerySuffix}`.trim();
    const image = await fetchImage(query);

    const payload: VocabularyPayload = {
      ...generated,
      query,
      imageUrl: image.imageUrl,
      imageSource: image.imageSource,
    };

    await writeLog({ category, item: payload, status: 'success' });
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
