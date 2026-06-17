import { NextRequest, NextResponse } from 'next/server';
import {
  ensureAiWordGameDefaults,
  getAiWordCategories,
  getAiWordFallbackWords,
  getAiWordSettings,
  getBlockedTerms,
} from '@/lib/ai-word-game';
import { prisma } from '@/lib/prisma';

type AdminAction =
  | 'createCategory'
  | 'updateCategory'
  | 'deleteCategory'
  | 'createWord'
  | 'updateWord'
  | 'deleteWord'
  | 'createBlockedTerm'
  | 'updateBlockedTerm'
  | 'deleteBlockedTerm';

function cleanSlug(value: string) {
  return value.trim().toLowerCase().replace(/[^a-z0-9_-]+/g, '-').replace(/^-|-$/g, '');
}

function toBool(value: unknown, fallback = true) {
  return typeof value === 'boolean' ? value : fallback;
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
        updated_at = CURRENT_TIMESTAMP
    WHERE id = 'default'
  `;

  return NextResponse.json({ success: true });
}

export async function POST(request: NextRequest) {
  const body = await request.json();
  const action = body.action as AdminAction;

  if (action === 'createCategory') {
    const slug = cleanSlug(String(body.slug || body.label || 'category'));
    if (!slug) return NextResponse.json({ error: 'Slug is required' }, { status: 400 });
    await prisma.$executeRaw`
      INSERT INTO ai_word_category
        (id, slug, label, thai_label, icon, color, active, sort_order)
      VALUES
        (${crypto.randomUUID()}, ${slug}, ${String(body.label ?? slug)},
         ${body.thaiLabel ? String(body.thaiLabel) : null},
         ${body.icon ? String(body.icon) : null},
         ${body.color ? String(body.color) : null},
         ${toBool(body.active)}, ${Number(body.sortOrder ?? 0)})
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
        (id, category_id, word, thai_meaning, phonetic, active)
      VALUES
        (${crypto.randomUUID()}, ${String(body.categoryId)}, ${String(body.word ?? '')},
         ${body.thaiMeaning ? String(body.thaiMeaning) : null},
         ${body.phonetic ? String(body.phonetic) : null},
         ${toBool(body.active)})
    `;
  } else if (action === 'updateWord') {
    await prisma.$executeRaw`
      UPDATE ai_word_fallback_word
      SET category_id = ${String(body.categoryId)},
          word = ${String(body.word ?? '')},
          thai_meaning = ${body.thaiMeaning ? String(body.thaiMeaning) : null},
          phonetic = ${body.phonetic ? String(body.phonetic) : null},
          active = ${toBool(body.active)},
          updated_at = CURRENT_TIMESTAMP
      WHERE id = ${String(body.id)}
    `;
  } else if (action === 'deleteWord') {
    await prisma.$executeRaw`
      DELETE FROM ai_word_fallback_word WHERE id = ${String(body.id)}
    `;
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
