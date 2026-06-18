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
  active: boolean;
};

const defaultCategories = [
  {
    slug: 'animals',
    label: 'Animals',
    thaiLabel: 'สัตว์',
    icon: 'pets',
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
    icon: 'restaurant',
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
    icon: 'directions_car',
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
    icon: 'park',
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
    INSERT INTO ai_word_game_settings (id, updated_at)
    VALUES ('default', CURRENT_TIMESTAMP)
    ON CONFLICT (id) DO NOTHING
  `;

  for (const [index, category] of defaultCategories.entries()) {
    const existing = await prisma.$queryRaw<CategoryRow[]>`
      SELECT * FROM ai_word_category WHERE slug = ${category.slug} LIMIT 1
    `;

    let categoryId = existing[0]?.id;
    if (!categoryId) {
      categoryId = crypto.randomUUID();
      await prisma.$executeRaw`
        INSERT INTO ai_word_category
          (id, slug, label, thai_label, icon, color, active, sort_order, updated_at)
        VALUES
          (${categoryId}, ${category.slug}, ${category.label}, ${category.thaiLabel},
           ${category.icon}, ${category.color}, true, ${index}, CURRENT_TIMESTAMP)
      `;
    }

    const wordCount = await prisma.$queryRaw<Array<{ count: bigint }>>`
      SELECT COUNT(*)::bigint AS count
      FROM ai_word_fallback_word
      WHERE category_id = ${categoryId}
    `;
    if (Number(wordCount[0]?.count ?? 0) > 0) continue;

    for (const word of category.words) {
      await prisma.$executeRaw`
        INSERT INTO ai_word_fallback_word
          (id, category_id, word, thai_meaning, phonetic, active, updated_at)
        VALUES
          (${crypto.randomUUID()}, ${categoryId}, ${word[0]}, ${word[1]}, ${word[2]}, true, CURRENT_TIMESTAMP)
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
