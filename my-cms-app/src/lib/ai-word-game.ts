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
