import { prisma } from '@/lib/prisma';

export type AiWordSettings = {
  enabled: boolean;
  showInApp: boolean;
  title: string;
  description: string;
  coverImageUrl: string;
  maxScore: number;
  useGemini: boolean;
  usePixabay: boolean;
  usePexels: boolean;
  imageProviderOrder: string;
  geminiModel: string;
  promptTemplate: string;
  imageQuerySuffix: string;
  wordsPerSessionEasy: number;
  wordsPerSessionMedium: number;
  wordsPerSessionHard: number;
  timeLimitMinutes: number;
  enableSafeSearch: boolean;
};

export type AiWordCategory = {
  id: string;
  slug: string;
  label: string;
  thaiLabel: string | null;
  icon: string | null;
  color: string | null;
  active: boolean;
  sortOrder: number;
};

export type AiWordFallbackWord = {
  id: string;
  categoryId: string;
  word: string;
  thaiMeaning: string | null;
  phonetic: string | null;
  imageUrl: string | null;
  difficulty: 'easy' | 'medium' | 'hard';
  active: boolean;
};

export type SpaceAdventureArea = {
  id: string;
  name: string;
  imageUrl: string;
  items: string[];
  active: boolean;
  sortOrder: number;
  createdAt?: Date;
  updatedAt?: Date;
};

type SettingsRow = {
  enabled: boolean;
  show_in_app: boolean;
  title: string;
  description: string;
  cover_image_url: string;
  max_score: number;
  use_gemini: boolean;
  use_pixabay: boolean;
  use_pexels: boolean;
  image_provider_order: string;
  gemini_model: string;
  prompt_template: string;
  image_query_suffix: string;
  words_per_session_easy: number;
  words_per_session_medium: number;
  words_per_session_hard: number;
  time_limit_minutes: number;
  enable_safe_search: boolean;
};

type CategoryRow = {
  id: string;
  slug: string;
  label: string;
  thai_label: string | null;
  icon: string | null;
  color: string | null;
  active: boolean;
  sort_order: number;
};

type WordRow = {
  id: string;
  category_id: string;
  word: string;
  thai_meaning: string | null;
  phonetic: string | null;
  image_url: string | null;
  difficulty: 'easy' | 'medium' | 'hard';
  active: boolean;
};

function extractGeminiJson(text: string, kind: 'array' | 'object'): unknown | null {
  const cleaned = text
    .trim()
    .replace(/^```(?:json)?\s*/i, '')
    .replace(/\s*```$/i, '');

  try {
    return JSON.parse(cleaned);
  } catch {
    const match = kind === 'array'
      ? cleaned.match(/\[[\s\S]*\]/)
      : cleaned.match(/\{[\s\S]*\}/);
    if (!match) return null;

    try {
      return JSON.parse(match[0]);
    } catch {
      return null;
    }
  }
}

function normalizeSpaceAdventureItems(items: unknown): string[] {
  const rawItems = Array.isArray(items)
    ? items
    : String(items ?? '')
        .split(',')
        .map((item) => item.trim());

  return Array.from(new Set(
    rawItems
      .map((item) => String(item).trim().toLowerCase())
      .filter(Boolean)
  ));
}

function mapSpaceAdventureArea(row: {
  id: string;
  name: string;
  imageUrl: string | null;
  items: unknown;
  active: boolean;
  sortOrder: number;
  createdAt?: Date;
  updatedAt?: Date;
}): SpaceAdventureArea {
  return {
    id: row.id,
    name: row.name,
    imageUrl: row.imageUrl ?? '',
    items: normalizeSpaceAdventureItems(row.items),
    active: row.active,
    sortOrder: row.sortOrder,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

const defaultCategories = [
  {
    slug: 'animals',
    label: 'Animals',
    thaiLabel: 'สัตว์',
    icon: '🦁',
    color: '#66BB6A',
    words: [
      ['Octopus', 'ปลาหมึกยักษ์', 'OK-tuh-pus'],
      ['Dolphin', 'โลมา', 'DOL-fin'],
      ['Penguin', 'เพนกวิน', 'PEN-gwin'],
    ],
  },
  {
    slug: 'food',
    label: 'Food',
    thaiLabel: 'อาหาร',
    icon: '🍎',
    color: '#FF9800',
    words: [
      ['Apple', 'แอปเปิล', 'AP-pul'],
      ['Cookie', 'คุกกี้', 'KUH-kee'],
      ['Carrot', 'แครอท', 'KAIR-uht'],
    ],
  },
  {
    slug: 'vehicles',
    label: 'Vehicles',
    thaiLabel: 'ยานพาหนะ',
    icon: '🚀',
    color: '#0D92F4',
    words: [
      ['Rocket', 'จรวด', 'ROK-it'],
      ['Bicycle', 'จักรยาน', 'BY-sih-kul'],
      ['Train', 'รถไฟ', 'TRAYN'],
    ],
  },
  {
    slug: 'nature',
    label: 'Nature',
    thaiLabel: 'ธรรมชาติ',
    icon: '🌈',
    color: '#1AAA88',
    words: [
      ['Rainbow', 'สายรุ้ง', 'RAYN-boh'],
      ['Flower', 'ดอกไม้', 'FLOW-er'],
      ['Mountain', 'ภูเขา', 'MOWN-tin'],
    ],
  },
];

export async function ensureAiWordGameDefaults() {
  await prisma.$executeRaw`
    CREATE TABLE IF NOT EXISTS ai_word_game_settings (
      id TEXT PRIMARY KEY DEFAULT 'default',
      enabled BOOLEAN NOT NULL DEFAULT true,
      show_in_app BOOLEAN NOT NULL DEFAULT true,
      title TEXT NOT NULL DEFAULT 'Voice Quest',
      description TEXT NOT NULL DEFAULT '',
      cover_image_url TEXT NOT NULL DEFAULT 'asset:assets/images/voice_quest_cover.png',
      max_score INTEGER NOT NULL DEFAULT 100,
      use_gemini BOOLEAN NOT NULL DEFAULT true,
      use_pixabay BOOLEAN NOT NULL DEFAULT true,
      use_pexels BOOLEAN NOT NULL DEFAULT true,
      image_provider_order TEXT NOT NULL DEFAULT 'pixabay,pexels',
      gemini_model TEXT NOT NULL DEFAULT 'gemini-2.0-flash',
      prompt_template TEXT NOT NULL DEFAULT '',
      image_query_suffix TEXT NOT NULL DEFAULT 'cartoon illustration for kids',
      created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  `;

  await prisma.$executeRaw`
    ALTER TABLE ai_word_game_settings
      ADD COLUMN IF NOT EXISTS words_per_session_easy INTEGER NOT NULL DEFAULT 3,
      ADD COLUMN IF NOT EXISTS words_per_session_medium INTEGER NOT NULL DEFAULT 5,
      ADD COLUMN IF NOT EXISTS words_per_session_hard INTEGER NOT NULL DEFAULT 7,
      ADD COLUMN IF NOT EXISTS time_limit_minutes INTEGER NOT NULL DEFAULT 10,
      ADD COLUMN IF NOT EXISTS enable_safe_search BOOLEAN NOT NULL DEFAULT true
  `;

  await prisma.$executeRaw`
    ALTER TABLE ai_word_fallback_word
      ADD COLUMN IF NOT EXISTS image_url TEXT,
      ADD COLUMN IF NOT EXISTS difficulty TEXT NOT NULL DEFAULT 'easy'
  `;

  await prisma.$executeRaw`
    INSERT INTO ai_word_game_settings (id, prompt_template, updated_at)
    VALUES ('default', 'You are an expert children''s English vocabulary teacher. Generate exactly one simple English vocabulary word for kids ages 4-9 that belongs STRICTLY and directly to the category: {{category}} (Thai label/concept: {{thaiLabel}}).\n\nCategory Guidelines:\n- Animals (สัตว์): Must be a direct animal species (e.g., cat, dog, elephant, rabbit, turtle, dolphin, bee). Do NOT suggest food, vehicles, or places.\n- Food (อาหาร): Must be a direct edible food, fruit, vegetable, snack, or drink (e.g., apple, banana, cookie, bread, carrot, pizza, milk). Do NOT suggest animals or tools.\n- Vehicles (ยานพาหนะ): Must be a direct mode of transport (e.g., car, train, rocket, bicycle, boat, plane, tractor). Do NOT suggest roads, places, or jobs.\n- Nature (ธรรมชาติ): Must be a direct nature element, plant, flower, weather, or celestial body (e.g., tree, flower, rainbow, star, mountain, cloud, rain, sun). Do NOT suggest man-made items.\n- Bedroom (ห้องนอน): Must be a typical item found in a child''s bedroom (e.g., bed, pillow, blanket, lamp, toy, clock).\n- School (โรงเรียน) / Classroom: Must be a typical item found in a classroom or school (e.g., book, pencil, ruler, desk, chair, bag).\n\nCRITICAL CONSTRAINTS:\n1. The word MUST belong strictly to the category "{{category}}". Do NOT suggest words from other categories under any circumstances.\n2. The word MUST NOT be in this list of already existing words (case-insensitive): {{excludeList}}.\n3. The word must be a simple, concrete noun that a young child can understand and can be easily drawn in a kid-friendly cartoon illustration.\n4. Difficulty guidance:\n   - easy: 3-5 letters (e.g. cat, sun, apple)\n   - medium: 5-7 letters (e.g. rabbit, carrot, rocket, flower)\n   - hard: 7+ letters (e.g. elephant, butterfly, mountain)\n\nReturn the result in JSON format only:\n{\n  "word": "EnglishWord",\n  "thaiMeaning": "คำแปลภาษาไทยสั้นๆ ที่เข้าใจง่ายสำหรับเด็ก",\n  "phonetic": "phonetic guide for kids (e.g. AP-pul, PEN-gwin, ROK-it)"\n}', CURRENT_TIMESTAMP)
    ON CONFLICT (id) DO UPDATE SET
      prompt_template = CASE WHEN ai_word_game_settings.prompt_template = '' THEN 'You are an expert children''s English vocabulary teacher. Generate exactly one simple English vocabulary word for kids ages 4-9 that belongs STRICTLY and directly to the category: {{category}} (Thai label/concept: {{thaiLabel}}).\n\nCategory Guidelines:\n- Animals (สัตว์): Must be a direct animal species (e.g., cat, dog, elephant, rabbit, turtle, dolphin, bee). Do NOT suggest food, vehicles, or places.\n- Food (อาหาร): Must be a direct edible food, fruit, vegetable, snack, or drink (e.g., apple, banana, cookie, bread, carrot, pizza, milk). Do NOT suggest animals or tools.\n- Vehicles (ยานพาหนะ): Must be a direct mode of transport (e.g., car, train, rocket, bicycle, boat, plane, tractor). Do NOT suggest roads, places, or jobs.\n- Nature (ธรรมชาติ): Must be a direct nature element, plant, flower, weather, or celestial body (e.g., tree, flower, rainbow, star, mountain, cloud, rain, sun). Do NOT suggest man-made items.\n- Bedroom (ห้องนอน): Must be a typical item found in a child''s bedroom (e.g., bed, pillow, blanket, lamp, toy, clock).\n- School (โรงเรียน) / Classroom: Must be a typical item found in a classroom or school (e.g., book, pencil, ruler, desk, chair, bag).\n\nCRITICAL CONSTRAINTS:\n1. The word MUST belong strictly to the category "{{category}}". Do NOT suggest words from other categories under any circumstances.\n2. The word MUST NOT be in this list of already existing words (case-insensitive): {{excludeList}}.\n3. The word must be a simple, concrete noun that a young child can understand and can be easily drawn in a kid-friendly cartoon illustration.\n4. Difficulty guidance:\n   - easy: 3-5 letters (e.g. cat, sun, apple)\n   - medium: 5-7 letters (e.g. rabbit, carrot, rocket, flower)\n   - hard: 7+ letters (e.g. elephant, butterfly, mountain)\n\nReturn the result in JSON format only:\n{\n  "word": "EnglishWord",\n  "thaiMeaning": "คำแปลภาษาไทยสั้นๆ ที่เข้าใจง่ายสำหรับเด็ก",\n  "phonetic": "phonetic guide for kids (e.g. AP-pul, PEN-gwin, ROK-it)"\n}' ELSE ai_word_game_settings.prompt_template END
  `;

  for (const [index, category] of defaultCategories.entries()) {
    const existing = await prisma.$queryRaw<CategoryRow[]>`
      SELECT * FROM ai_word_category WHERE slug = ${category.slug} LIMIT 1
    `;

    let categoryId = existing[0]?.id;
    let createdCategory = false;
    if (!categoryId) {
      categoryId = crypto.randomUUID();
      createdCategory = true;
      await prisma.$executeRaw`
        INSERT INTO ai_word_category
          (id, slug, label, thai_label, icon, color, active, sort_order, updated_at)
        VALUES
          (${categoryId}, ${category.slug}, ${category.label}, ${category.thaiLabel},
           ${category.icon}, ${category.color}, true, ${index}, CURRENT_TIMESTAMP)
      `;
    }

    if (!createdCategory) continue;

    for (const word of category.words) {
      await prisma.$executeRaw`
        INSERT INTO ai_word_fallback_word
          (id, category_id, word, thai_meaning, phonetic, image_url, difficulty, active, updated_at)
        VALUES
          (${crypto.randomUUID()}, ${categoryId}, ${word[0]}, ${word[1]}, ${word[2]}, null, 'easy', true, CURRENT_TIMESTAMP)
      `;
    }
  }
}

export function mapSettings(row: SettingsRow): AiWordSettings {
  return {
    enabled: row.enabled,
    showInApp: row.show_in_app,
    title: row.title,
    description: row.description,
    coverImageUrl: row.cover_image_url,
    maxScore: row.max_score,
    useGemini: row.use_gemini,
    usePixabay: row.use_pixabay,
    usePexels: row.use_pexels,
    imageProviderOrder: row.image_provider_order,
    geminiModel: row.gemini_model,
    promptTemplate: row.prompt_template,
    imageQuerySuffix: row.image_query_suffix,
    wordsPerSessionEasy: row.words_per_session_easy,
    wordsPerSessionMedium: row.words_per_session_medium,
    wordsPerSessionHard: row.words_per_session_hard,
    timeLimitMinutes: row.time_limit_minutes,
    enableSafeSearch: row.enable_safe_search,
  };
}

export function mapCategory(row: CategoryRow): AiWordCategory {
  return {
    id: row.id,
    slug: row.slug,
    label: row.label,
    thaiLabel: row.thai_label,
    icon: row.icon,
    color: row.color,
    active: row.active,
    sortOrder: row.sort_order,
  };
}

export function mapWord(row: WordRow): AiWordFallbackWord {
  return {
    id: row.id,
    categoryId: row.category_id,
    word: row.word,
    thaiMeaning: row.thai_meaning,
    phonetic: row.phonetic,
    imageUrl: row.image_url,
    difficulty: row.difficulty,
    active: row.active,
  };
}

export async function getAiWordSettings() {
  await ensureAiWordGameDefaults();
  const rows = await prisma.$queryRaw<SettingsRow[]>`
    SELECT * FROM ai_word_game_settings WHERE id = 'default' LIMIT 1
  `;
  return mapSettings(rows[0]);
}

export async function getAiWordCategories({ activeOnly = false } = {}) {
  await ensureAiWordGameDefaults();
  const rows = activeOnly
    ? await prisma.$queryRaw<CategoryRow[]>`
        SELECT * FROM ai_word_category
        WHERE active = true
        ORDER BY sort_order ASC, label ASC
      `
    : await prisma.$queryRaw<CategoryRow[]>`
        SELECT * FROM ai_word_category
        ORDER BY sort_order ASC, label ASC
      `;
  return rows.map(mapCategory);
}

export async function getAiWordFallbackWords(categoryId?: string, activeOnly = false) {
  const rows = categoryId
    ? activeOnly
      ? await prisma.$queryRaw<WordRow[]>`
          SELECT * FROM ai_word_fallback_word
          WHERE category_id = ${categoryId} AND active = true
          ORDER BY word ASC
        `
      : await prisma.$queryRaw<WordRow[]>`
          SELECT * FROM ai_word_fallback_word
          WHERE category_id = ${categoryId}
          ORDER BY word ASC
        `
    : await prisma.$queryRaw<WordRow[]>`
        SELECT * FROM ai_word_fallback_word
        ORDER BY word ASC
      `;
  return rows.map(mapWord);
}

export async function getAiWordFallbackWordsByDifficulty(
  categoryId: string,
  difficulty: 'easy' | 'medium' | 'hard',
  activeOnly = true,
) {
  const rows = activeOnly
    ? await prisma.$queryRaw<WordRow[]>`
        SELECT * FROM ai_word_fallback_word
        WHERE category_id = ${categoryId} AND difficulty = ${difficulty} AND active = true
        ORDER BY word ASC
      `
    : await prisma.$queryRaw<WordRow[]>`
        SELECT * FROM ai_word_fallback_word
        WHERE category_id = ${categoryId} AND difficulty = ${difficulty}
        ORDER BY word ASC
      `;
  return rows.map(mapWord);
}

export async function getBlockedTerms() {
  return prisma.$queryRaw<Array<{ id: string; term: string; active: boolean }>>`
    SELECT id, term, active
    FROM ai_word_blocked_term
    ORDER BY term ASC
  `;
}

export async function isBlockedWord(word: string) {
  const normalized = word.trim().toLowerCase();
  if (!normalized) return true;
  const rows = await prisma.$queryRaw<Array<{ term: string }>>`
    SELECT term FROM ai_word_blocked_term WHERE active = true
  `;
  return rows.some((row) => normalized.includes(row.term.toLowerCase()));
}

export function buildVirtualAiWordActivity(settings: AiWordSettings) {
  return {
    activityId: 'ai-word-game',
    nameActivity: settings.title,
    category: 'LANGUAGE',
    descriptionActivity: settings.description,
    createdAt: new Date().toISOString(),
    responses: 0,
    id: 'ai-word-game',
    name: settings.title,
    difficulty: 'EASY',
    maxScore: settings.maxScore,
    content: 'AI Word Game',
    description: settings.description,
    videoUrl: '',
    thumbnailUrl: settings.coverImageUrl,
    tiktokHtmlContent: '',
    segments: null,
    playCount: 0,
    parentId: null,
    isPublic: true,
    updatedAt: new Date().toISOString(),
    isAiWordGame: true,
  };
}

export async function shouldInjectAiWordActivity(category: string | null, ownedBy: string | null) {
  if (ownedBy) return null;
  const settings = await getAiWordSettings();
  if (!settings.enabled || !settings.showInApp) return null;
  const normalized = (category || '').trim().toUpperCase();
  if (normalized && normalized !== 'ALL' && normalized !== 'LANGUAGE' && category !== 'ด้านภาษา') {
    return null;
  }
  return buildVirtualAiWordActivity(settings);
}

export function buildVirtualSpaceAdventure() {
  return {
    activityId: 'space-adventure',
    nameActivity: 'Space Adventure',
    category: 'LANGUAGE',
    descriptionActivity: 'Scan your room with Vision AI & find hidden cosmic items!',
    createdAt: new Date().toISOString(),
    responses: 0,
    id: 'space-adventure',
    name: 'Space Adventure',
    difficulty: 'EASY',
    maxScore: 100,
    content: 'Space Adventure',
    description: 'Scan your room with Vision AI & find hidden cosmic items!',
    videoUrl: '',
    thumbnailUrl: '',
    tiktokHtmlContent: '',
    segments: null,
    playCount: 150,
    parentId: null,
    isPublic: true,
    updatedAt: new Date().toISOString(),
  };
}

export async function shouldInjectSpaceAdventure(category: string | null, ownedBy: string | null) {
  if (ownedBy) return null;
  const normalized = (category || '').trim().toUpperCase();
  if (normalized && normalized !== 'ALL' && normalized !== 'LANGUAGE' && category !== 'ด้านภาษา') {
    return null;
  }
  return buildVirtualSpaceAdventure();
}

export async function ensureSpaceAdventureSettings() {
  await prisma.$executeRaw`
    CREATE TABLE IF NOT EXISTS "GameSetting" (
      "id" TEXT NOT NULL DEFAULT 'default',
      "scorePerItem" INTEGER NOT NULL DEFAULT 10,
      "timerLimit" INTEGER NOT NULL DEFAULT 60,
      "updatedAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
      CONSTRAINT "GameSetting_pkey" PRIMARY KEY ("id")
    )
  `;

  await prisma.$executeRaw`
    CREATE TABLE IF NOT EXISTS "GameScore" (
      "id" TEXT NOT NULL,
      "playerName" TEXT NOT NULL DEFAULT 'Space Adventurer',
      "score" INTEGER NOT NULL,
      "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
      CONSTRAINT "GameScore_pkey" PRIMARY KEY ("id")
    )
  `;

  await prisma.$executeRaw`
    CREATE TABLE IF NOT EXISTS "SpaceAdventureArea" (
      "id" TEXT NOT NULL,
      "name" TEXT NOT NULL,
      "imageUrl" TEXT,
      "items" JSONB NOT NULL DEFAULT '[]'::jsonb,
      "active" BOOLEAN NOT NULL DEFAULT true,
      "sortOrder" INTEGER NOT NULL DEFAULT 0,
      "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
      "updatedAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
      CONSTRAINT "SpaceAdventureArea_pkey" PRIMARY KEY ("id")
    )
  `;

  await prisma.$executeRaw`
    INSERT INTO "GameSetting" ("id", "scorePerItem", "timerLimit", "updatedAt")
    VALUES ('default', 10, 60, CURRENT_TIMESTAMP)
    ON CONFLICT ("id") DO NOTHING
  `;
}

export async function getSpaceAdventureSettings() {
  await ensureSpaceAdventureSettings();
  const settings = await prisma.$queryRaw<Array<{
    id: string;
    scorePerItem: number;
    timerLimit: number;
    updatedAt: Date;
  }>>`
    SELECT "id", "scorePerItem", "timerLimit", "updatedAt"
    FROM "GameSetting"
    WHERE "id" = 'default'
    LIMIT 1
  `;
  return settings[0] || { id: 'default', scorePerItem: 10, timerLimit: 60 };
}

export async function updateSpaceAdventureSettings(scorePerItem: number, timerLimit: number) {
  await ensureSpaceAdventureSettings();
  const settings = await prisma.$queryRaw<Array<{
    id: string;
    scorePerItem: number;
    timerLimit: number;
    updatedAt: Date;
  }>>`
    UPDATE "GameSetting"
    SET "scorePerItem" = ${scorePerItem},
        "timerLimit" = ${timerLimit},
        "updatedAt" = CURRENT_TIMESTAMP
    WHERE "id" = 'default'
    RETURNING "id", "scorePerItem", "timerLimit", "updatedAt"
  `;
  return settings[0];
}

export async function getSpaceAdventureAreas(options: { activeOnly?: boolean } = {}) {
  await ensureSpaceAdventureSettings();
  const rows = options.activeOnly
    ? await prisma.$queryRaw<Array<{
        id: string;
        name: string;
        imageUrl: string | null;
        items: unknown;
        active: boolean;
        sortOrder: number;
        createdAt: Date;
        updatedAt: Date;
      }>>`
        SELECT "id", "name", "imageUrl", "items", "active", "sortOrder", "createdAt", "updatedAt"
        FROM "SpaceAdventureArea"
        WHERE "active" = true
        ORDER BY "sortOrder" ASC, "name" ASC
      `
    : await prisma.$queryRaw<Array<{
        id: string;
        name: string;
        imageUrl: string | null;
        items: unknown;
        active: boolean;
        sortOrder: number;
        createdAt: Date;
        updatedAt: Date;
      }>>`
        SELECT "id", "name", "imageUrl", "items", "active", "sortOrder", "createdAt", "updatedAt"
        FROM "SpaceAdventureArea"
        ORDER BY "sortOrder" ASC, "name" ASC
      `;

  return rows.map(mapSpaceAdventureArea);
}

export async function upsertSpaceAdventureArea(input: {
  id?: string;
  name: string;
  imageUrl?: string;
  items: unknown;
  active?: boolean;
  sortOrder?: number;
}) {
  await ensureSpaceAdventureSettings();
  const id = input.id?.trim() || crypto.randomUUID();
  const name = input.name.trim();
  const items = normalizeSpaceAdventureItems(input.items);
  if (!name) throw new Error('Area name is required.');
  if (items.length === 0) throw new Error('At least one item is required.');

  const rows = await prisma.$queryRaw<Array<{
    id: string;
    name: string;
    imageUrl: string | null;
    items: unknown;
    active: boolean;
    sortOrder: number;
    createdAt: Date;
    updatedAt: Date;
  }>>`
    INSERT INTO "SpaceAdventureArea" ("id", "name", "imageUrl", "items", "active", "sortOrder", "createdAt", "updatedAt")
    VALUES (
      ${id},
      ${name},
      ${input.imageUrl?.trim() || ''},
      ${JSON.stringify(items)}::jsonb,
      ${input.active ?? true},
      ${Number(input.sortOrder ?? 0)},
      CURRENT_TIMESTAMP,
      CURRENT_TIMESTAMP
    )
    ON CONFLICT ("id") DO UPDATE SET
      "name" = EXCLUDED."name",
      "imageUrl" = EXCLUDED."imageUrl",
      "items" = EXCLUDED."items",
      "active" = EXCLUDED."active",
      "sortOrder" = EXCLUDED."sortOrder",
      "updatedAt" = CURRENT_TIMESTAMP
    RETURNING "id", "name", "imageUrl", "items", "active", "sortOrder", "createdAt", "updatedAt"
  `;

  return mapSpaceAdventureArea(rows[0]);
}

export async function deleteSpaceAdventureArea(id: string) {
  await ensureSpaceAdventureSettings();
  await prisma.$executeRaw`
    DELETE FROM "SpaceAdventureArea"
    WHERE "id" = ${id}
  `;
}

export async function scanRoomImage(base64Image: string): Promise<{ objects: string[]; source: 'gemini'; fallback: false } | { objects: string[]; source: 'none'; fallback: true; reason: string }> {
  const apiKey = process.env.GEMINI_API_KEY || process.env.GOOGLE_GENERATIVE_AI_API_KEY;
  const geminiModel = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
  if (!apiKey) {
    return {
      objects: [],
      source: 'none',
      fallback: true,
      reason: 'GEMINI_API_KEY is missing from environment.'
    };
  }

  const prompt = `You are an AI spatial scanner for a children's adventure game called 'Space Adventure'. Analyze this room photo. Detect 5-10 common everyday objects (like bed, pillow, chair, desk, toy, book, shoe, window, curtain, keyboard, monitor, blanket, cup, bag) that a child can easily find and take a close-up photo of. Return a JSON array of strings representing these objects in simple, concrete English terms (e.g. ["pillow", "chair", "bed", "book"]). Respond ONLY with JSON, no markdown blocks or other text.`;

  const cleanBase64 = base64Image.replace(/^data:image\/\w+;base64,/, '');

  try {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{
            parts: [
              { text: prompt },
              {
                inlineData: {
                  mimeType: 'image/jpeg',
                  data: cleanBase64
                }
              }
            ]
          }],
          generationConfig: {
            responseMimeType: 'application/json',
            responseSchema: {
              type: 'ARRAY',
              items: { type: 'STRING' }
            },
            temperature: 0.4,
            maxOutputTokens: 512
          }
        })
      }
    );

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Gemini API error (${response.status}): ${errorText}`);
    }

    const result = await response.json();
    const text = result.candidates?.[0]?.content?.parts?.[0]?.text || '';
    const parsed = extractGeminiJson(text, 'array');
    if (Array.isArray(parsed)) {
      const objects = parsed
        .map((item: unknown) => String(item).trim().toLowerCase())
        .filter(Boolean);
      if (objects.length > 0) return { objects, source: 'gemini', fallback: false };
    }
    return {
      objects: [],
      source: 'none',
      fallback: true,
      reason: 'Gemini did not return a valid list of room objects.'
    };
  } catch (e) {
    console.error('Failed to scan room image with Gemini:', e);
    return {
      objects: [],
      source: 'none',
      fallback: true,
      reason: e instanceof Error ? e.message : 'Unknown Gemini scan error.'
    };
  }
}

export async function verifyTargetItem(base64Image: string, targetObject: string): Promise<{ match: boolean; confidence: number; reason: string }> {
  const apiKey = process.env.GEMINI_API_KEY || process.env.GOOGLE_GENERATIVE_AI_API_KEY;
  const geminiModel = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY is missing from environment.');
  }

  const prompt = `You are the referee AI for the 'Space Adventure' game. A child was asked to find the object: "${targetObject}". Verify if the uploaded image represents a close-up or clear shot of this target object. It doesn't have to be perfect, but it must be clearly identifiable as the target object. Respond in JSON format ONLY:
{
  "match": true/false,
  "confidence": 0.0 to 1.0,
  "reason": "Brief feedback in English encouraging the child (e.g., 'Very Good! You found the pillow!') or explaining why it didn't match (e.g., 'Oops, that looks like something else. Try to find the pillow!')"
}`;

  const cleanBase64 = base64Image.replace(/^data:image\/\w+;base64,/, '');

  try {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{
            parts: [
              { text: prompt },
              {
                inlineData: {
                  mimeType: 'image/jpeg',
                  data: cleanBase64
                }
              }
            ]
          }],
          generationConfig: {
            responseMimeType: 'application/json',
            responseSchema: {
              type: 'OBJECT',
              properties: {
                match: { type: 'BOOLEAN' },
                confidence: { type: 'NUMBER' },
                reason: { type: 'STRING' }
              },
              required: ['match', 'confidence', 'reason']
            },
            temperature: 0.4,
            maxOutputTokens: 512
          }
        })
      }
    );

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Gemini API error (${response.status}): ${errorText}`);
    }

    const result = await response.json();
    const text = result.candidates?.[0]?.content?.parts?.[0]?.text || '';
    const parsed = extractGeminiJson(text, 'object') as Record<string, unknown> | null;
    if (!parsed) throw new Error('Gemini did not return valid verification JSON.');
    return {
      match: Boolean(parsed.match),
      confidence: Number(parsed.confidence ?? 0.8),
      reason: String(parsed.reason ?? 'Very Good!')
    };
  } catch (e) {
    console.error('Failed to verify item with Gemini:', e);
    const reason = e instanceof Error ? e.message : 'Unknown Gemini verification error.';
    return {
      match: false,
      confidence: 0,
      reason: `Verification failed because the AI service returned an error: ${reason}`
    };
  }
}

export async function saveGameScore(playerName: string, score: number) {
  await ensureSpaceAdventureSettings();
  const rows = await prisma.$queryRaw<Array<{
    id: string;
    playerName: string;
    score: number;
    createdAt: Date;
  }>>`
    INSERT INTO "GameScore" ("id", "playerName", "score")
    VALUES (${crypto.randomUUID()}, ${playerName}, ${score})
    RETURNING "id", "playerName", "score", "createdAt"
  `;
  return rows[0];
}

export async function getTopScores(limit = 10) {
  await ensureSpaceAdventureSettings();
  return prisma.$queryRaw<Array<{
    id: string;
    playerName: string;
    score: number;
    createdAt: Date;
  }>>`
    SELECT "id", "playerName", "score", "createdAt"
    FROM "GameScore"
    ORDER BY "score" DESC
    LIMIT ${limit}
  `;
}

