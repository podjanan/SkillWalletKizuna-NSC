import { NextRequest, NextResponse } from 'next/server';
import {
  AiWordCategory,
  ensureAiWordGameDefaults,
  getAiWordCategories,
  getAiWordFallbackWords,
  getAiWordSettings,
  getBlockedTerms,
  isBlockedWord,
} from '@/lib/ai-word-game';
import { prisma } from '@/lib/prisma';
import { uploadToMinio } from '@/lib/minio';

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

const fallbackMetadata: Record<string, { thaiMeaning: string; phonetic: string }> = {
  bed: { thaiMeaning: 'เตียงนอน', phonetic: 'BED' },
  blanket: { thaiMeaning: 'ผ้าห่ม', phonetic: 'BLANG-kit' },
  pillow: { thaiMeaning: 'หมอน', phonetic: 'PIL-oh' },
  lamp: { thaiMeaning: 'โคมไฟ', phonetic: 'LAMP' },
  clock: { thaiMeaning: 'นาฬิกา', phonetic: 'KLOK' },
  toy: { thaiMeaning: 'ของเล่น', phonetic: 'TOY' },
  pencil: { thaiMeaning: 'ดินสอ', phonetic: 'PEN-sul' },
  ruler: { thaiMeaning: 'ไม้บรรทัด', phonetic: 'ROO-ler' },
  desk: { thaiMeaning: 'โต๊ะเขียนหนังสือ', phonetic: 'DESK' },
  chair: { thaiMeaning: 'เก้าอี้', phonetic: 'CHAIR' },
  bag: { thaiMeaning: 'กระเป๋า', phonetic: 'BAG' },
  eraser: { thaiMeaning: 'ยางลบ', phonetic: 'ih-RAY-ser' },
  apple: { thaiMeaning: 'แอปเปิล', phonetic: 'AP-pul' },
  airplane: { thaiMeaning: 'เครื่องบิน', phonetic: 'AIR-playn' },
  banana: { thaiMeaning: 'กล้วย', phonetic: 'buh-NA-nuh' },
  bear: { thaiMeaning: 'หมี', phonetic: 'BAIR' },
  bee: { thaiMeaning: 'ผึ้ง', phonetic: 'BEE' },
  bicycle: { thaiMeaning: 'จักรยาน', phonetic: 'BY-sih-kul' },
  bird: { thaiMeaning: 'นก', phonetic: 'BERD' },
  boat: { thaiMeaning: 'เรือ', phonetic: 'BOHT' },
  book: { thaiMeaning: 'หนังสือ', phonetic: 'BUK' },
  bread: { thaiMeaning: 'ขนมปัง', phonetic: 'BRED' },
  bus: { thaiMeaning: 'รถบัส', phonetic: 'BUS' },
  butterfly: { thaiMeaning: 'ผีเสื้อ', phonetic: 'BUT-er-fly' },
  cake: { thaiMeaning: 'เค้ก', phonetic: 'KAYK' },
  car: { thaiMeaning: 'รถยนต์', phonetic: 'KAHR' },
  carrot: { thaiMeaning: 'แครอท', phonetic: 'KAIR-uht' },
  cat: { thaiMeaning: 'แมว', phonetic: 'KAT' },
  cheese: { thaiMeaning: 'เนยแข็ง', phonetic: 'CHEEZ' },
  chicken: { thaiMeaning: 'ไก่', phonetic: 'CHIK-in' },
  cloud: { thaiMeaning: 'เมฆ', phonetic: 'KLOWD' },
  cookie: { thaiMeaning: 'คุกกี้', phonetic: 'KUH-kee' },
  cow: { thaiMeaning: 'วัว', phonetic: 'KOW' },
  crab: { thaiMeaning: 'ปู', phonetic: 'KRAB' },
  dog: { thaiMeaning: 'สุนัข', phonetic: 'DAWG' },
  dolphin: { thaiMeaning: 'โลมา', phonetic: 'DOL-fin' },
  duck: { thaiMeaning: 'เป็ด', phonetic: 'DUK' },
  egg: { thaiMeaning: 'ไข่', phonetic: 'EG' },
  elephant: { thaiMeaning: 'ช้าง', phonetic: 'EL-uh-funt' },
  fish: { thaiMeaning: 'ปลา', phonetic: 'FISH' },
  flower: { thaiMeaning: 'ดอกไม้', phonetic: 'FLOW-er' },
  frog: { thaiMeaning: 'กบ', phonetic: 'FRAWG' },
  giraffe: { thaiMeaning: 'ยีราฟ', phonetic: 'juh-RAF' },
  grass: { thaiMeaning: 'หญ้า', phonetic: 'GRAS' },
  helicopter: { thaiMeaning: 'เฮลิคอปเตอร์', phonetic: 'HEL-ih-kop-ter' },
  horse: { thaiMeaning: 'ม้า', phonetic: 'HORS' },
  icecream: { thaiMeaning: 'ไอศกรีม', phonetic: 'YS-KREEM' },
  juice: { thaiMeaning: 'น้ำผลไม้', phonetic: 'JOOS' },
  lion: { thaiMeaning: 'สิงโต', phonetic: 'LYE-un' },
  milk: { thaiMeaning: 'นม', phonetic: 'MILK' },
  monkey: { thaiMeaning: 'ลิง', phonetic: 'MUN-kee' },
  moon: { thaiMeaning: 'ดวงจันทร์', phonetic: 'MOON' },
  mountain: { thaiMeaning: 'ภูเขา', phonetic: 'MOWN-tin' },
  octopus: { thaiMeaning: 'ปลาหมึกยักษ์', phonetic: 'OK-tuh-pus' },
  orange: { thaiMeaning: 'ส้ม', phonetic: 'OR-inj' },
  owl: { thaiMeaning: 'นกฮูก', phonetic: 'OWL' },
  penguin: { thaiMeaning: 'เพนกวิน', phonetic: 'PEN-gwin' },
  pig: { thaiMeaning: 'หมู', phonetic: 'PIG' },
  pizza: { thaiMeaning: 'พิซซ่า', phonetic: 'PEET-suh' },
  rabbit: { thaiMeaning: 'กระต่าย', phonetic: 'RAB-it' },
  rain: { thaiMeaning: 'ฝน', phonetic: 'RAYN' },
  rainbow: { thaiMeaning: 'สายรุ้ง', phonetic: 'RAYN-boh' },
  rice: { thaiMeaning: 'ข้าว', phonetic: 'RYS' },
  rocket: { thaiMeaning: 'จรวด', phonetic: 'ROK-it' },
  shark: { thaiMeaning: 'ฉลาม', phonetic: 'SHAHRK' },
  sheep: { thaiMeaning: 'แกะ', phonetic: 'SHEEP' },
  sky: { thaiMeaning: 'ท้องฟ้า', phonetic: 'SKY' },
  snow: { thaiMeaning: 'หิมะ', phonetic: 'SNOH' },
  spider: { thaiMeaning: 'แมงมุม', phonetic: 'SPY-der' },
  star: { thaiMeaning: 'ดาว', phonetic: 'STAHR' },
  submarine: { thaiMeaning: 'เรือดำน้ำ', phonetic: 'sub-muh-REEN' },
  sun: { thaiMeaning: 'ดวงอาทิตย์', phonetic: 'SUN' },
  tiger: { thaiMeaning: 'เสือ', phonetic: 'TY-ger' },
  train: { thaiMeaning: 'รถไฟ', phonetic: 'TRAYN' },
  tree: { thaiMeaning: 'ต้นไม้', phonetic: 'TREE' },
  truck: { thaiMeaning: 'รถบรรทุก', phonetic: 'TRUK' },
  turtle: { thaiMeaning: 'เต่า', phonetic: 'TER-tul' },
  whale: { thaiMeaning: 'วาฬ', phonetic: 'WAYL' },
  wind: { thaiMeaning: 'ลม', phonetic: 'WIND' },
  zebra: { thaiMeaning: 'ม้าลาย', phonetic: 'ZEE-bruh' },
};

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
async function generateSuggestion(category: AiWordCategory, difficulty: 'easy' | 'medium' | 'hard') {
  const settings = await getAiWordSettings();
  const apiKey = process.env.GEMINI_API_KEY || process.env.GOOGLE_GENERATIVE_AI_API_KEY;
  const geminiModel = process.env.GEMINI_MODEL || settings.geminiModel;
  if (!settings.useGemini) {
    throw new Error('Gemini suggestion is disabled in AI Word Game settings.');
  }
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY is missing from env.');
  }

  // Fetch existing words to exclude them from suggestions
  const existingWords = await getAiWordFallbackWords(category.id);
  const existingWordSet = new Set(existingWords.map((w) => w.word.trim().toLowerCase()));

  let lastError = '';

  for (let attempts = 0; attempts < 3; attempts++) {
    const excludeList = Array.from(existingWordSet).join(', ');
    const prompt = `You are an expert children's English vocabulary teacher. Generate exactly one simple English vocabulary word for kids ages 4-9 that belongs STRICTLY and directly to the category: ${category.label} (Thai concept: ${category.thaiLabel || ''}).
Selected difficulty: ${difficulty}.

Category Guidelines:
- Animals (สัตว์): Must be a direct animal species (e.g., cat, dog, elephant, rabbit, turtle, dolphin, bee). Do NOT suggest food, vehicles, or places.
- Food (อาหาร): Must be a direct edible food, fruit, vegetable, snack, or drink (e.g., apple, banana, cookie, bread, carrot, pizza, milk). Do NOT suggest animals or tools.
- Vehicles (ยานพาหนะ): Must be a direct mode of transport (e.g., car, train, rocket, bicycle, boat, plane, tractor). Do NOT suggest roads, places, or jobs.
- Nature (ธรรมชาติ): Must be a direct nature element, plant, flower, weather, or celestial body (e.g., tree, flower, rainbow, star, mountain, cloud, rain, sun). Do NOT suggest man-made items.
- Bedroom (ห้องนอน): Must be a typical item found in a child's bedroom (e.g., bed, pillow, blanket, lamp, toy, clock).
- School (โรงเรียน) / Classroom: Must be a typical item found in a classroom or school (e.g., book, pencil, ruler, desk, chair, bag).

CRITICAL CONSTRAINTS:
1. The word MUST belong strictly to the category "${category.label}". Do NOT suggest words from other categories under any circumstances.
2. The word MUST NOT be in this list of already existing words (case-insensitive): ${excludeList}.
3. The word must be a simple, concrete noun that a young child can understand and can be easily drawn in a kid-friendly cartoon illustration.
4. Difficulty guidance:
   - easy: 3-5 letters (e.g. cat, sun, apple)
   - medium: 5-7 letters (e.g. rabbit, carrot, rocket, flower)
   - hard: 7+ letters (e.g. elephant, butterfly, mountain)

Return the result in JSON format ONLY:
{
  "word": "EnglishWord",
  "thaiMeaning": "คำแปลภาษาไทยสั้นๆ ที่เข้าใจง่ายสำหรับเด็ก",
  "phonetic": "คำสะกดเสียงพจนานุกรม เช่น AP-pul หรือ ZEE-bruh"
}`;

    try {
      const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent?key=${apiKey}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            contents: [{ role: 'user', parts: [{ text: prompt }] }],
            generationConfig: {
              responseMimeType: 'application/json',
              temperature: 0.7,
              maxOutputTokens: 1024,
              thinkingConfig: { thinkingBudget: 0 },
            },
          }),
        },
      );

      if (!response.ok) {
        const error = new Error(await getGeminiErrorMessage(response)) as Error & { status?: number };
        error.status = response.status;
        throw error;
      }

      const data = await response.json();
      const candidate = data?.candidates?.[0];
      const text = candidate?.content?.parts?.map((part: { text?: string }) => part.text ?? '').join('') ?? '';
      const parsed = extractJson(text);
      const word = parsed?.word ? String(parsed.word).trim() : '';
      const thaiMeaning = parsed?.thaiMeaning ? String(parsed.thaiMeaning).trim() : '';
      const phonetic = parsed?.phonetic ? String(parsed.phonetic).trim() : '';

      if (!word) {
        lastError = candidate?.finishReason === 'MAX_TOKENS'
          ? 'Gemini response was truncated before it returned a vocabulary word.'
          : 'Gemini did not return a vocabulary word.';
        continue;
      }
      if (existingWordSet.has(word.toLowerCase())) {
        lastError = `Gemini returned a duplicate word: ${word}`;
        continue;
      }
      if (await isBlockedWord(word)) {
        lastError = `Gemini returned a blocked word: ${word}`;
        continue;
      }

      return {
        word,
        thaiMeaning: thaiMeaning || getFallbackMetadata(word).thaiMeaning,
        phonetic: phonetic || getFallbackMetadata(word).phonetic,
        source: 'gemini',
      };
    } catch (e) {
      lastError = e instanceof Error ? e.message : 'Gemini suggestion failed.';
      console.error('Gemini suggest exception:', e);
    }
  }

  throw new Error(lastError || 'Gemini could not generate a vocabulary word.');
}

async function enrichWord(word: string, category: AiWordCategory, difficulty: 'easy' | 'medium' | 'hard') {
  const settings = await getAiWordSettings();
  const apiKey = process.env.GEMINI_API_KEY || process.env.GOOGLE_GENERATIVE_AI_API_KEY;
  const geminiModel = process.env.GEMINI_MODEL || settings.geminiModel;
  const fallback = getFallbackMetadata(word);
  if (!settings.useGemini) {
    throw new Error('Gemini metadata generation is disabled in AI Word Game settings.');
  }
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY is missing from env.');
  }

  const prompt = [
    'Create metadata for an English vocabulary game for Thai children.',
    `Word: ${word}`,
    `Category: ${category.label}`,
    `Difficulty: ${difficulty}`,
    'Return only JSON with keys: word, thaiMeaning, phonetic.',
    'Phonetic should be simple kid-friendly English syllables.',
  ].join('\n');

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        generationConfig: {
          responseMimeType: 'application/json',
          temperature: 0.4,
          maxOutputTokens: 1024,
          thinkingConfig: { thinkingBudget: 0 },
        },
      }),
    },
  );

  if (!response.ok) {
    const error = new Error(await getGeminiErrorMessage(response)) as Error & { status?: number };
    error.status = response.status;
    throw error;
  }
  const data = await response.json();
  const text = data?.candidates?.[0]?.content?.parts?.map((part: { text?: string }) => part.text ?? '').join('') ?? '';
  const parsed = extractJson(text);
  return {
    word: parsed?.word ? String(parsed.word).trim() : word,
    thaiMeaning: parsed?.thaiMeaning ? String(parsed.thaiMeaning).trim() : fallback.thaiMeaning,
    phonetic: parsed?.phonetic ? String(parsed.phonetic).trim() : fallback.phonetic,
    source: 'gemini',
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
        gemini_model = ${String(body.geminiModel ?? 'gemini-2.0-flash')},
        prompt_template = ${String(body.promptTemplate ?? '')},
        image_query_suffix = ${String(body.imageQuerySuffix ?? 'cartoon illustration for kids')},
        words_per_session_easy = ${Number(body.wordsPerSessionEasy ?? 3)},
        words_per_session_medium = ${Number(body.wordsPerSessionMedium ?? 5)},
        words_per_session_hard = ${Number(body.wordsPerSessionHard ?? 7)},
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
      animals: 'pets',
      food: 'restaurant',
      vehicles: 'directions_car',
      nature: 'park',
      bedroom: 'bed',
      school: 'school',
      classroom: 'school',
    };
    const defaultIcon = iconMap[slug] ?? 'folder';
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
    await prisma.$executeRaw`
      INSERT INTO ai_word_fallback_word
        (id, category_id, word, thai_meaning, phonetic, image_url, difficulty, active, updated_at)
      VALUES
        (${crypto.randomUUID()}, ${String(body.categoryId)}, ${String(body.word ?? '')},
         ${body.thaiMeaning ? String(body.thaiMeaning) : null},
         ${body.phonetic ? String(body.phonetic) : null},
         ${body.imageUrl ? String(body.imageUrl) : null},
         ${toDifficulty(body.difficulty)},
         ${toBool(body.active)}, CURRENT_TIMESTAMP)
    `;
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
    try {
      const suggestion = await generateSuggestion(category, difficulty);
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
      const message = e instanceof Error ? e.message : 'Gemini suggestion failed.';
      const status = e instanceof Error && 'status' in e && e.status === 429 ? 429 : 502;
      return NextResponse.json({ error: message, source: 'gemini' }, { status });
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
      const message = e instanceof Error ? e.message : 'Gemini metadata generation failed.';
      const status = e instanceof Error && 'status' in e && e.status === 429 ? 429 : 502;
      return NextResponse.json({ error: message, source: 'gemini' }, { status });
    }
  } else if (action === 'refreshImage') {
    const word = String(body.word ?? '').trim();
    if (!word) return NextResponse.json({ error: 'Word is required' }, { status: 400 });
    const imageInfo = await fetchPreviewImage(word);
    return NextResponse.json({
      ...imageInfo,
      imageError: imageInfo.error,
    });
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
