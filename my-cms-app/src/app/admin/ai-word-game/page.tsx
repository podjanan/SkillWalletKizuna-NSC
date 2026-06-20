'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  ImageIcon,
  Plus,
  RefreshCcw,
  Save,
  Search,
  Sparkles,
  Trash2,
  BookOpen,
  Sliders,
  Check,
  Image as ImageIconLucide,
  HelpCircle,
  Smile
} from 'lucide-react';
import UserProfile from '@/components/UserProfile';

type Difficulty = 'easy' | 'medium' | 'hard';

type Settings = {
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

type Category = {
  id: string;
  slug: string;
  label: string;
  thaiLabel: string | null;
  icon: string | null;
  color: string | null;
  active: boolean;
  sortOrder: number;
};

type FallbackWord = {
  id: string;
  categoryId: string;
  word: string;
  thaiMeaning: string | null;
  phonetic: string | null;
  imageUrl: string | null;
  difficulty: Difficulty;
  active: boolean;
};

type BlockedTerm = {
  id: string;
  term: string;
  active: boolean;
};

type GenerationLog = {
  id: string;
  categorySlug: string;
  word: string | null;
  imageSource: string | null;
  wordSource: string | null;
  status: string;
  error: string | null;
  createdAt: string;
};

type AdminData = {
  settings: Settings;
  categories: Category[];
  words: FallbackWord[];
  blockedTerms: BlockedTerm[];
  logs: GenerationLog[];
};

type PreviewWord = {
  word: string;
  thaiMeaning: string;
  phonetic: string;
  imageUrl: string;
  imageSource?: string;
  query?: string;
  imageError?: string;
  difficulty: Difficulty;
};

const emptyCategory: Category = {
  id: '',
  slug: '',
  label: '',
  thaiLabel: '',
  icon: '',
  color: '#0D92F4',
  active: true,
  sortOrder: 0,
};

const emptyWord: FallbackWord = {
  id: '',
  categoryId: '',
  word: '',
  thaiMeaning: '',
  phonetic: '',
  imageUrl: '',
  difficulty: 'easy',
  active: true,
};

const difficultyClasses: Record<Difficulty, string> = {
  easy: 'bg-green-50 text-green-700 border-green-200',
  medium: 'bg-amber-50 text-amber-800 border-amber-200',
  hard: 'bg-red-50 text-red-700 border-red-200',
};

const emojiOptions = [
  '🦁', '🐶', '🐱', '🐰', '🐢', '🐬', '🐝', '🦋',
  '🍎', '🍌', '🍪', '🥕', '🍕', '🥛', '🥤', '🍰',
  '🚀', '🚗', '🚲', '🚂', '✈️', '🚢', '🚌', '🚁',
  '🌈', '🌳', '🌸', '⭐', '☀️', '🌙', '☁️', '⛰️',
  '📚', '✏️', '🎒', '💻', '🧮', '🎨', '🧸', '✨',
];

function emojiForCategoryIcon(icon: string | null | undefined, slug = '') {
  const raw = (icon ?? '').trim();
  const legacy: Record<string, string> = {
    pets: '🦁',
    restaurant: '🍎',
    directions_car: '🚀',
    vehicle: '🚀',
    park: '🌈',
    nature: '🌈',
    bed: '🛏️',
    school: '📚',
    folder: '✨',
    category: '✨',
  };
  if (raw && !legacy[raw]) return raw;

  const normalized = slug.toLowerCase();
  if (normalized.includes('animal')) return '🦁';
  if (normalized.includes('food')) return '🍎';
  if (normalized.includes('vehicle')) return '🚀';
  if (normalized.includes('nature')) return '🌈';
  if (normalized.includes('school') || normalized.includes('study')) return '📚';
  if (normalized.includes('drink')) return '🥤';
  if (normalized.includes('computer')) return '💻';
  return legacy[raw] ?? '✨';
}

function normalizeCategoryIcon(category: Category): Category {
  return {
    ...category,
    icon: emojiForCategoryIcon(category.icon, category.slug),
  };
}

const defaultPromptTemplate = `You are an expert children's English vocabulary teacher. Generate exactly one simple English vocabulary word for kids ages 4-9 that belongs STRICTLY and directly to the category: {{category}} (Thai label/concept: {{thaiLabel}}).

Category Guidelines:
- Animals (สัตว์): Must be a direct animal species (e.g., cat, dog, elephant, rabbit, turtle, dolphin, bee). Do NOT suggest food, vehicles, or places.
- Food (อาหาร): Must be a direct edible food, fruit, vegetable, snack, or drink (e.g., apple, banana, cookie, bread, carrot, pizza, milk). Do NOT suggest animals or tools.
- Vehicles (ยานพาหนะ): Must be a direct mode of transport (e.g., car, train, rocket, bicycle, boat, plane, tractor). Do NOT suggest roads, places, or jobs.
- Nature (ธรรมชาติ): Must be a direct nature element, plant, flower, weather, or celestial body (e.g., tree, flower, rainbow, star, mountain, cloud, rain, sun). Do NOT suggest man-made items.
- Bedroom (ห้องนอน): Must be a typical item found in a child's bedroom (e.g., bed, pillow, blanket, lamp, toy, clock).
- School (โรงเรียน) / Classroom: Must be a typical item found in a classroom or school (e.g., book, pencil, ruler, desk, chair, bag).

CRITICAL CONSTRAINTS:
1. The word MUST belong strictly to the category "{{category}}". Do NOT suggest words from other categories under any circumstances.
2. The word MUST NOT be in this list of already existing words (case-insensitive): {{excludeList}}.
3. The word must be a simple, concrete noun that a young child can understand and can be easily drawn in a kid-friendly cartoon illustration.
4. Difficulty guidance:
   - easy: 3-5 letters (e.g. cat, sun, apple)
   - medium: 5-7 letters (e.g. rabbit, carrot, rocket, flower)
   - hard: 7+ letters (e.g. elephant, butterfly, mountain)

Return the result in JSON format only:
{
  "word": "EnglishWord",
  "thaiMeaning": "คำแปลภาษาไทยสั้นๆ ที่เข้าใจง่ายสำหรับเด็ก",
  "phonetic": "คำสะกดเสียงพจนานุกรม เช่น AP-pul, ZEE-bruh"
}`;

export default function AiWordGamePage() {
  const [data, setData] = useState<AdminData | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [activeTab, setActiveTab] = useState<'studio' | 'bank' | 'settings'>('studio');
  const [filterCategory, setFilterCategory] = useState<string>('all');
  const [newCategory, setNewCategory] = useState<Category>(emptyCategory);
  const [creator, setCreator] = useState<FallbackWord>(emptyWord);
  const [preview, setPreview] = useState<PreviewWord | null>(null);
  const [creatorStatus, setCreatorStatus] = useState('');
  const [suggestedHistory, setSuggestedHistory] = useState<string[]>([]);

  const [showAdvancedCategories, setShowAdvancedCategories] = useState(false);

  const activeCategories = useMemo(() => data?.categories.filter((category) => category.active) ?? [], [data?.categories]);
  
  const wordsByCategory = useMemo(() => {
    const map: Record<string, FallbackWord[]> = {};
    for (const word of data?.words ?? []) {
      map[word.categoryId] = [...(map[word.categoryId] ?? []), word];
    }
    return map;
  }, [data?.words]);

  const selectedCategory = activeCategories.find((category) => category.id === creator.categoryId) ?? activeCategories[0];

  const loadData = useCallback(async () => {
    setLoading(true);
    const res = await fetch('/api/admin/ai-word-game');
    const json = await res.json();
    json.categories = (json.categories ?? []).map(normalizeCategoryIcon);
    setData(json);
    const firstCategory = json.categories?.[0];
    setCreator((prev) => ({ ...prev, categoryId: prev.categoryId || firstCategory?.id || '' }));
    setLoading(false);
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  useEffect(() => {
    setSuggestedHistory([]);
  }, [creator.categoryId, creator.difficulty]);

  async function saveSettings() {
    if (!data) return;
    setSaving(true);
    await fetch('/api/admin/ai-word-game', {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data.settings),
    });
    await loadData();
    setSaving(false);
  }

  async function runAction(payload: Record<string, unknown>, reload = true) {
    const res = await fetch('/api/admin/ai-word-game', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    const json = await res.json().catch(() => ({}));
    if (reload) await loadData();
    return json;
  }

  async function suggestWord() {
    setCreatorStatus('Asking Gemini for a word...');
    setPreview(null);

    const currentWordLower = creator.word.trim().toLowerCase();
    const excludeList = Array.from(new Set([
      ...(currentWordLower ? [currentWordLower] : []),
      ...suggestedHistory.map((w) => w.trim().toLowerCase())
    ])).filter(Boolean);

    const result = await runAction(
      {
        action: 'suggestWord',
        categoryId: creator.categoryId,
        difficulty: creator.difficulty,
        exclude: excludeList
      },
      false,
    );
    if (result.error) {
      setCreatorStatus(`Gemini failed: ${String(result.error)}`);
      return;
    }
    const word = String(result.word ?? '');
    const thaiMeaning = String(result.thaiMeaning ?? '');
    const phonetic = String(result.phonetic ?? '');
    const imageUrl = String(result.imageUrl ?? '');

    setCreator((prev) => ({
      ...prev,
      word,
      thaiMeaning,
      phonetic,
      imageUrl,
    }));

    setPreview({
      word,
      thaiMeaning,
      phonetic,
      imageUrl,
      imageSource: result.imageSource ? String(result.imageSource) : undefined,
      query: result.query ? String(result.query) : undefined,
      imageError: result.imageError ? String(result.imageError) : undefined,
      difficulty: creator.difficulty,
    });

    if (word) {
      setSuggestedHistory((prev) => Array.from(new Set([...prev, word.trim().toLowerCase()])));
    }

    setCreatorStatus(result.imageError ? `Gemini word ready (image lookup failed: ${result.imageError})` : 'Gemini suggestion and image ready.');
  }

  async function previewWord() {
    if (!creator.word.trim()) return;
    setCreatorStatus('Creating preview...');
    const result = await runAction(
      {
        action: 'previewWord',
        categoryId: creator.categoryId,
        difficulty: creator.difficulty,
        word: creator.word,
      },
      false,
    );
    if (result.error) {
      setCreatorStatus(`Gemini failed: ${String(result.error)}`);
      return;
    }
    const nextPreview: PreviewWord = {
      word: String(result.word ?? creator.word),
      thaiMeaning: String(result.thaiMeaning ?? ''),
      phonetic: String(result.phonetic ?? ''),
      imageUrl: String(result.imageUrl ?? ''),
      imageSource: result.imageSource ? String(result.imageSource) : undefined,
      query: result.query ? String(result.query) : undefined,
      imageError: result.imageError ? String(result.imageError) : undefined,
      difficulty: creator.difficulty,
    };
    setPreview(nextPreview);
    setCreator((prev) => ({
      ...prev,
      word: nextPreview.word,
      thaiMeaning: nextPreview.thaiMeaning,
      phonetic: nextPreview.phonetic,
      imageUrl: nextPreview.imageUrl,
    }));
    setCreatorStatus(result.imageError ? `Preview ready (image lookup failed: ${result.imageError})` : 'Preview ready for approval.');
  }

  async function refreshPreviewImage() {
    const word = preview?.word || creator.word;
    if (!word.trim()) return;
    setCreatorStatus('Refreshing image...');
    const result = await runAction({ action: 'refreshImage', word }, false);
    const imageUrl = String(result.imageUrl ?? '');
    const imageError = result.imageError ? String(result.imageError) : undefined;
    setPreview((prev) => prev ? { ...prev, imageUrl, imageError, imageSource: String(result.imageSource ?? ''), query: String(result.query ?? '') } : prev);
    setCreator((prev) => ({ ...prev, imageUrl }));
    setCreatorStatus(result.imageError ? `Image refresh failed: ${result.imageError}` : 'Image refreshed.');
  }

  async function saveCreatorWord() {
    if (!creator.categoryId || !creator.word.trim()) return;
    setCreatorStatus('Saving word...');
    await runAction({
      action: 'createWord',
      ...creator,
      thaiMeaning: creator.thaiMeaning || preview?.thaiMeaning || null,
      phonetic: creator.phonetic || preview?.phonetic || null,
      imageUrl: creator.imageUrl || preview?.imageUrl || null,
    });
    const categoryId = creator.categoryId;
    const difficulty = creator.difficulty;
    setCreator({ ...emptyWord, categoryId, difficulty });
    setPreview(null);
    setSuggestedHistory([]);
    setCreatorStatus('Word saved to the system.');
  }

  if (loading || !data) {
    return (
      <div className="flex h-full min-h-[70vh] items-center justify-center">
        <div className="flex flex-col items-center gap-3">
          <RefreshCcw className="animate-spin text-primary" size={32} />
          <div className="body-large-medium text-secondary--text">Loading Voice Quest Dashboard...</div>
        </div>
      </div>
    );
  }

  const { settings } = data;

  return (
    <div className="p-8 max-w-7xl mx-auto">
      {/* Top Banner */}
      <div className="mb-8 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <div className="body-small-regular mb-1 text-secondary--text">CMS Tools &gt; Interactive Activities</div>
          <h1 className="text-3xl font-extrabold tracking-tight text-slate-900 flex items-center gap-2">
            VOICE QUEST <span className="text-xs px-2 py-0.5 bg-indigo-50 text-indigo-600 rounded-full font-bold border border-indigo-100">STUDIO</span>
          </h1>
          <p className="body-small-regular text-secondary--text mt-1">Refine, preview, and manage sticker assets for the vocabulary speech game.</p>
        </div>
        <UserProfile />
      </div>

      {/* Tabs Menu */}
      <div className="flex border-b border-slate-200 mb-8 gap-6">
        <button
          onClick={() => setActiveTab('studio')}
          className={`flex items-center gap-2 pb-4 px-1 border-b-2 font-semibold text-sm transition-all duration-200 ${
            activeTab === 'studio'
              ? 'border-indigo-600 text-indigo-600'
              : 'border-transparent text-slate-500 hover:text-slate-700'
          }`}
        >
          <Sparkles size={18} />
          🎨 Creator Studio
        </button>
        <button
          onClick={() => setActiveTab('bank')}
          className={`flex items-center gap-2 pb-4 px-1 border-b-2 font-semibold text-sm transition-all duration-200 ${
            activeTab === 'bank'
              ? 'border-indigo-600 text-indigo-600'
              : 'border-transparent text-slate-500 hover:text-slate-700'
          }`}
        >
          <BookOpen size={18} />
          📚 Playable Word Bank
        </button>
        <button
          onClick={() => setActiveTab('settings')}
          className={`flex items-center gap-2 pb-4 px-1 border-b-2 font-semibold text-sm transition-all duration-200 ${
            activeTab === 'settings'
              ? 'border-indigo-600 text-indigo-600'
              : 'border-transparent text-slate-500 hover:text-slate-700'
          }`}
        >
          <Sliders size={18} />
          Settings
        </button>
      </div>

      {/* Content Area */}
      <div>
        {/* TAB 1: CREATOR STUDIO */}
        {activeTab === 'studio' && (
          <div className="grid grid-cols-1 lg:grid-cols-[1fr_380px] gap-8 items-start">
            
            {/* Left Box: Controls */}
            <div className="space-y-6">
              <div className="bg-white rounded-2xl border border-slate-200/80 p-6 shadow-sm">
                <div className="mb-6 flex flex-wrap items-center justify-between gap-3">
                  <div>
                    <h2 className="text-lg font-bold text-slate-900">1. Ideation & Transcription</h2>
                    <p className="text-xs text-slate-500 mt-0.5">Choose a category and let Gemini brainstorm a unique word, or type it manually.</p>
                  </div>
                  {creatorStatus && (
                    <span className="text-xs font-semibold bg-slate-50 border border-slate-100 text-slate-600 px-3 py-1 rounded-full flex items-center gap-1.5 animate-pulse">
                      <span className="w-1.5 h-1.5 bg-slate-400 rounded-full"></span>
                      {creatorStatus}
                    </span>
                  )}
                </div>

                <div className="grid grid-cols-1 md:grid-cols-[1.5fr_1.2fr_2fr] gap-4 mb-6">
                  <div className="flex flex-col gap-1.5">
                    <label className="text-xs font-semibold text-slate-600">Vocabulary Category</label>
                    <select
                      value={creator.categoryId}
                      onChange={(e) => {
                        setCreator({ ...creator, categoryId: e.target.value });
                        setPreview(null);
                      }}
                      className="rounded-xl border border-slate-200 px-3 py-2.5 text-sm font-medium bg-slate-50/50 hover:bg-slate-50 focus:border-indigo-500 outline-none transition-all duration-200"
                    >
                      {activeCategories.map((c) => (
                        <option key={c.id} value={c.id}>{c.label}</option>
                      ))}
                    </select>
                  </div>

                  <div className="flex flex-col gap-1.5">
                    <label className="text-xs font-semibold text-slate-600">Difficulty Grade</label>
                    <DifficultySelect
                      value={creator.difficulty}
                      onChange={(difficulty) => {
                        setCreator({ ...creator, difficulty });
                        setPreview(null);
                      }}
                    />
                  </div>

                  <div className="flex flex-col gap-1.5">
                    <label className="text-xs font-semibold text-slate-600">English Word</label>
                    <div className="relative flex items-center">
                      <input
                        placeholder="e.g. Octopus, Elephant, Rocket"
                        value={creator.word}
                        onChange={(e) => {
                          setCreator({ ...creator, word: e.target.value });
                          setPreview(null);
                        }}
                        className="w-full rounded-xl border border-slate-200 pl-3 pr-10 py-2.5 text-sm font-semibold focus:border-indigo-500 outline-none transition-all duration-200"
                      />
                      <button
                        type="button"
                        onClick={(e) => {
                          e.preventDefault();
                          e.stopPropagation();
                          suggestWord();
                        }}
                        title="AI Suggest Word"
                        className="absolute right-2 p-1.5 text-indigo-600 hover:bg-indigo-50 rounded-lg transition-all duration-200"
                      >
                        <Sparkles size={16} />
                      </button>
                    </div>
                  </div>
                </div>

                {/* Meta details */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 border-t border-slate-100 pt-6">
                  <TextInput
                    label="Thai Translation"
                    placeholder="เช่น หญ้า, ดวงอาทิตย์"
                    value={creator.thaiMeaning ?? ''}
                    onChange={(thaiMeaning) => setCreator({ ...creator, thaiMeaning })}
                  />
                  <TextInput
                    label="PhoneticSynergy (คำสะกดเสียงพจนานุกรม)"
                    placeholder="เช่น GRAS, SUN"
                    value={creator.phonetic ?? ''}
                    onChange={(phonetic) => setCreator({ ...creator, phonetic })}
                  />
                </div>
              </div>

              {/* Extra tools */}
              <div className="bg-slate-50 border border-slate-200/50 rounded-2xl p-6 flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div className="flex items-start gap-3">
                  <div className="p-2.5 bg-indigo-50 text-indigo-600 rounded-xl">
                    <HelpCircle size={20} />
                  </div>
                  <div>
                    <h3 className="text-sm font-bold text-slate-900">How to add a sticker?</h3>
                    <p className="text-xs text-slate-500 max-w-md mt-0.5">Click the suggest button or type a word, make sure the category is correct, then use Find Sticker Image inside the preview studio.</p>
                  </div>
                </div>
                <button
                  onClick={previewWord}
                  disabled={!creator.word.trim()}
                  className="btn-primary flex items-center justify-center gap-2 rounded-xl px-5 py-3 shadow-md hover:shadow-indigo-100 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <Search size={18} />
                  Find Sticker Image
                </button>
              </div>
            </div>

            {/* Right Box: Sticker Preview */}
            <div className="sticky top-6">
              <PreviewCard
                preview={preview}
                category={selectedCategory}
                creator={creator}
                onRefresh={refreshPreviewImage}
                onSave={saveCreatorWord}
                creatorStatus={creatorStatus}
              />
            </div>

          </div>
        )}

        {/* TAB 2: PLAYABLE WORD BANK */}
        {activeTab === 'bank' && (
          <div className="space-y-8 animate-fadeIn">
            {/* Category filter pills */}
            <div className="flex flex-wrap gap-2 items-center">
              <span className="text-xs font-semibold text-slate-500 mr-2">Filter by Category:</span>
              <button
                onClick={() => setFilterCategory('all')}
                className={`text-xs px-3.5 py-2 rounded-xl font-bold border transition-all duration-200 ${
                  filterCategory === 'all'
                    ? 'bg-slate-900 border-slate-900 text-white shadow-sm'
                    : 'bg-white border-slate-200 text-slate-600 hover:bg-slate-50'
                }`}
              >
                🌍 All Words ({data.words.length})
              </button>
              {data.categories.map((c) => {
                const count = (wordsByCategory[c.id] ?? []).length;
                return (
                  <button
                    key={c.id}
                    onClick={() => setFilterCategory(c.id)}
                    className={`text-xs px-3.5 py-2 rounded-xl font-bold border transition-all duration-200 flex items-center gap-1.5 ${
                      filterCategory === c.id
                        ? 'text-white shadow-sm'
                        : 'bg-white border-slate-200 text-slate-600 hover:bg-slate-50'
                    }`}
                    style={filterCategory === c.id ? { backgroundColor: c.color || '#4F46E5', borderColor: c.color || '#4F46E5' } : {}}
                  >
                    <span>{c.label}</span>
                    <span className="opacity-75 font-medium">({count})</span>
                  </button>
                );
              })}
            </div>

            {/* Categorized Word Grids */}
            <div className="space-y-8">
              {data.categories
                .filter((cat) => filterCategory === 'all' || filterCategory === cat.id)
                .map((cat) => {
                  const words = wordsByCategory[cat.id] ?? [];
                  if (words.length === 0) return null;
                  return (
                    <div key={cat.id} className="bg-slate-50/50 border border-slate-200/50 rounded-2xl p-6">
                      <div className="flex items-center justify-between mb-4">
                        <div className="flex items-center gap-2.5">
                          <span
                            className="w-3.5 h-3.5 rounded-full"
                            style={{ backgroundColor: cat.color ?? '#4F46E5' }}
                          ></span>
                          <h3 className="text-base font-extrabold text-slate-950">{cat.label} ({cat.thaiLabel ?? ''})</h3>
                        </div>
                      </div>

                      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-4">
                        {words.map((word) => (
                          <WordRow
                            key={word.id}
                            word={word}
                            categories={data.categories}
                            onSave={(next) => runAction({ action: 'updateWord', ...next })}
                            onFindImage={async (next) => {
                              const result = await runAction({ action: 'refreshImage', word: next.word }, false);
                              const imageUrl = String(result.imageUrl ?? '');
                              if (imageUrl) {
                                await runAction({ action: 'updateWord', ...next, imageUrl });
                              }
                              return imageUrl;
                            }}
                            onDelete={() => runAction({ action: 'deleteWord', id: word.id })}
                          />
                        ))}
                      </div>
                    </div>
                  );
                })}
            </div>

            {/* Categories Management Panel */}
            <div className="bg-white rounded-2xl border border-slate-200/80 p-6 shadow-sm">
              <div className="flex items-center justify-between border-b border-slate-100 pb-4 mb-4">
                <div>
                  <h2 className="text-base font-bold text-slate-900">Manage Game Categories</h2>
                  <p className="text-xs text-slate-500">Edit metadata, color tags, sort orders, or add custom gameplay lists.</p>
                </div>
                <div className="flex items-center gap-3">
                  <button
                    type="button"
                    onClick={() => setShowAdvancedCategories(!showAdvancedCategories)}
                    className="text-xs font-bold text-indigo-600 hover:text-indigo-800 transition-colors duration-150 px-3 py-2 bg-slate-50 rounded-xl hover:bg-slate-100 border border-slate-100"
                  >
                    {showAdvancedCategories ? 'Hide Advanced Config' : 'Show Advanced Config'}
                  </button>
                  <button
                    onClick={async () => {
                      await runAction({ action: 'createCategory', ...newCategory });
                      setNewCategory(emptyCategory);
                    }}
                    className="btn-primary flex items-center gap-1.5 rounded-xl px-4 py-2.5 text-xs font-semibold shadow-sm hover:shadow-indigo-100 transition-all duration-200"
                  >
                    <Plus size={15} />
                    Add Category
                  </button>
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-3 mb-4">
                {showAdvancedCategories && (
                  <input placeholder="slug (e.g. food)" value={newCategory.slug} onChange={(e) => setNewCategory({ ...newCategory, slug: e.target.value })} className="rounded-xl border border-slate-200 px-3 py-2 text-xs font-medium focus:border-indigo-500 outline-none bg-slate-50/20" />
                )}
                <input placeholder="Category Name (e.g. Food)" value={newCategory.label} onChange={(e) => setNewCategory({ ...newCategory, label: e.target.value })} className="rounded-xl border border-slate-200 px-3 py-2 text-xs font-medium focus:border-indigo-500 outline-none bg-slate-50/20" />
                <input placeholder="Thai Label (e.g. อาหาร)" value={newCategory.thaiLabel ?? ''} onChange={(e) => setNewCategory({ ...newCategory, thaiLabel: e.target.value })} className="rounded-xl border border-slate-200 px-3 py-2 text-xs font-medium focus:border-indigo-500 outline-none bg-slate-50/20" />
                {showAdvancedCategories && (
                  <>
                    <EmojiInput value={newCategory.icon ?? ''} onChange={(icon) => setNewCategory({ ...newCategory, icon })} />
                    <input placeholder="Hex Color (e.g. #FF9800)" value={newCategory.color ?? ''} onChange={(e) => setNewCategory({ ...newCategory, color: e.target.value })} className="rounded-xl border border-slate-200 px-3 py-2 text-xs font-medium focus:border-indigo-500 outline-none bg-slate-50/20" />
                    <input placeholder="Sort Index" value={newCategory.sortOrder} onChange={(e) => setNewCategory({ ...newCategory, sortOrder: Number(e.target.value) || 0 })} className="rounded-xl border border-slate-200 px-3 py-2 text-xs font-medium focus:border-indigo-500 outline-none bg-slate-50/20" />
                  </>
                )}
              </div>

              <div className="overflow-x-auto">
                <table className="w-full min-w-[900px] text-xs">
                  <thead>
                    <tr className="bg-slate-50 border-y border-slate-100 text-slate-600 font-bold text-left">
                      {showAdvancedCategories && <th className="px-4 py-3">Slug</th>}
                      <th className="px-4 py-3">Category Name (English)</th>
                      <th className="px-4 py-3">Thai Label</th>
                      {showAdvancedCategories && (
                        <>
                          <th className="px-4 py-3">Emoji</th>
                          <th className="px-4 py-3">Theme Color</th>
                          <th className="px-4 py-3">Sort Order</th>
                        </>
                      )}
                      <th className="px-4 py-3">Active</th>
                      <th className="px-4 py-3 text-center">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 font-medium">
                    {data.categories.map((category) => (
                      <CategoryRow
                        key={category.id}
                        category={category}
                        showAdvanced={showAdvancedCategories}
                        onSave={(next) => runAction({ action: 'updateCategory', ...next })}
                        onDelete={() => runAction({ action: 'deleteCategory', id: category.id })}
                      />
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* TAB 3: Settings */}
        {activeTab === 'settings' && (
          <div className="space-y-6 animate-fadeIn">
            {/* System config */}
            <div className="bg-white rounded-2xl border border-slate-200/80 p-6 shadow-sm">
              <div className="mb-6 flex flex-wrap items-center justify-between gap-4">
                <div>
                  <h2 className="text-lg font-bold text-slate-900">System Parameters & Image Provider Config</h2>
                  <p className="text-xs text-slate-500 mt-0.5">Control difficulty quotas, API models, and search behavior.</p>
                </div>
                <button
                  onClick={saveSettings}
                  disabled={saving}
                  className="btn-primary flex items-center gap-2 rounded-xl px-5 py-2.5 text-sm font-semibold shadow-sm hover:shadow-indigo-100 transition-all duration-200"
                >
                  <Save size={16} />
                  {saving ? 'Saving...' : 'Save Settings'}
                </button>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4 mb-6">
                <Checkbox label="Enable Gameplay Screen" checked={settings.enabled} onChange={(enabled) => setData({ ...data, settings: { ...settings, enabled } })} />
                <Checkbox label="Show Card in Dashboard" checked={settings.showInApp} onChange={(showInApp) => setData({ ...data, settings: { ...settings, showInApp } })} />
                <Checkbox label="Use Gemini (AI Mode)" checked={settings.useGemini} onChange={(useGemini) => setData({ ...data, settings: { ...settings, useGemini } })} />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-6 border-t border-slate-100 py-6">
                <NumberInput label="Easy Mode Words Count" value={settings.wordsPerSessionEasy} onChange={(wordsPerSessionEasy) => setData({ ...data, settings: { ...settings, wordsPerSessionEasy } })} />
                <NumberInput label="Medium Mode Words Count" value={settings.wordsPerSessionMedium} onChange={(wordsPerSessionMedium) => setData({ ...data, settings: { ...settings, wordsPerSessionMedium } })} />
                <NumberInput label="Hard Mode Words Count" value={settings.wordsPerSessionHard} onChange={(wordsPerSessionHard) => setData({ ...data, settings: { ...settings, wordsPerSessionHard } })} />
                <NumberInput label="Time Limit (Minutes)" value={settings.timeLimitMinutes} max={120} onChange={(timeLimitMinutes) => setData({ ...data, settings: { ...settings, timeLimitMinutes } })} />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6 border-t border-slate-100 pt-6">
                <TextInput label="Game Card Title" value={settings.title} onChange={(title) => setData({ ...data, settings: { ...settings, title } })} />
                <TextInput label="Cover Image URL" value={settings.coverImageUrl} onChange={(coverImageUrl) => setData({ ...data, settings: { ...settings, coverImageUrl } })} />
                <TextInput label="Max Score" type="number" value={String(settings.maxScore)} onChange={(maxScore) => setData({ ...data, settings: { ...settings, maxScore: Number(maxScore) || 100 } })} />
              </div>

              <div className="mt-6 border-t border-slate-100 pt-6">
                <div>
                  <div className="flex items-center justify-between mb-1.5">
                    <span className="text-xs font-semibold text-slate-600 font-bold">Dynamic AI Prompt Template</span>
                    <button
                      type="button"
                      onClick={() => setData({ ...data, settings: { ...settings, promptTemplate: defaultPromptTemplate } })}
                      className="text-xs font-bold text-indigo-600 hover:text-indigo-850 hover:underline transition-all duration-150"
                    >
                      Reset to Default Prompt
                    </button>
                  </div>
                  <p className="text-[11px] text-slate-400 mb-1.5">Adjust template placeholders {"{{category}}"} or {"{{difficulty}}"} to customize vocabulary outputs.</p>
                  <textarea
                    value={settings.promptTemplate}
                    onChange={(e) => setData({ ...data, settings: { ...settings, promptTemplate: e.target.value } })}
                    className="w-full min-h-36 rounded-xl border border-slate-200 px-3 py-2 text-xs font-medium font-mono focus:border-indigo-500 outline-none transition-all duration-200 bg-slate-50/20"
                  />
                </div>
              </div>
            </div>


          </div>
        )}
      </div>
    </div>
  );
}

function TextInput({
  label,
  value,
  placeholder,
  onChange,
  type = 'text'
}: {
  label: string;
  value: string;
  placeholder?: string;
  onChange: (value: string) => void;
  type?: string;
}) {
  return (
    <label className="flex flex-col gap-1.5">
      <span className="text-xs font-semibold text-slate-600">{label}</span>
      <input
        type={type}
        placeholder={placeholder}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="w-full rounded-xl border border-slate-200 px-3 py-2 text-xs font-medium focus:border-indigo-500 outline-none bg-slate-50/20 focus:bg-white transition-all duration-200"
      />
    </label>
  );
}

function NumberInput({ label, value, onChange, max = 20 }: { label: string; value: number; onChange: (value: number) => void; max?: number }) {
  return (
    <label className="flex flex-col gap-1.5">
      <span className="text-xs font-semibold text-slate-600">{label}</span>
      <input
        type="number"
        min={1}
        max={max}
        value={value}
        onChange={(e) => onChange(Number(e.target.value) || 1)}
        className="w-full rounded-xl border border-slate-200 px-3 py-2 text-xs font-medium focus:border-indigo-500 outline-none bg-slate-50/20 focus:bg-white transition-all duration-200"
      />
    </label>
  );
}

function EmojiInput({
  value,
  onChange,
  compact = false,
}: {
  value: string;
  onChange: (value: string) => void;
  compact?: boolean;
}) {
  const [open, setOpen] = useState(false);

  return (
    <div className="relative">
      <div className="flex items-center gap-1.5">
        <input
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder="🍎"
          className={`${compact ? 'h-9' : 'h-10'} w-full rounded-lg border border-slate-200 px-2.5 py-1.5 text-center text-lg font-semibold focus:border-indigo-500 outline-none bg-slate-50/20`}
        />
        <button
          type="button"
          onClick={() => setOpen((next) => !next)}
          className={`${compact ? 'h-9 w-9' : 'h-10 w-10'} shrink-0 rounded-lg border border-slate-200 bg-slate-50 text-slate-700 hover:bg-indigo-50 hover:text-indigo-700 transition-all duration-150 flex items-center justify-center`}
          title="Open emoji picker"
        >
          <Smile size={compact ? 15 : 17} />
        </button>
      </div>

      {open && (
        <div className="absolute right-0 z-30 mt-2 w-64 rounded-2xl border border-slate-200 bg-white p-3 shadow-xl">
          <div className="mb-2 text-[11px] font-bold text-slate-500">Choose emoji</div>
          <div className="grid grid-cols-8 gap-1.5">
            {emojiOptions.map((emoji) => (
              <button
                key={emoji}
                type="button"
                onClick={() => {
                  onChange(emoji);
                  setOpen(false);
                }}
                className="h-8 w-8 rounded-lg text-lg hover:bg-indigo-50 transition-colors"
              >
                {emoji}
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

function Checkbox({ label, checked, onChange }: { label: string; checked: boolean; onChange: (checked: boolean) => void }) {
  return (
    <label className="flex items-center gap-3 rounded-xl bg-slate-50 border border-slate-200/50 p-4 hover:bg-slate-100/50 transition-all duration-150 cursor-pointer select-none">
      <input
        type="checkbox"
        checked={checked}
        onChange={(e) => onChange(e.target.checked)}
        className="rounded text-indigo-600 focus:ring-indigo-500 w-4 h-4"
      />
      <span className="text-xs font-bold text-slate-800">{label}</span>
    </label>
  );
}

function DifficultySelect({ value, onChange }: { value: Difficulty; onChange: (value: Difficulty) => void }) {
  return (
    <select
      value={value}
      onChange={(e) => onChange(e.target.value as Difficulty)}
      className="rounded-xl border border-slate-200 px-3 py-2.5 text-sm font-medium bg-slate-50/50 hover:bg-slate-50 focus:border-indigo-500 outline-none transition-all duration-200"
    >
      <option value="easy">🟩 Easy (ง่าย)</option>
      <option value="medium">🟨 Medium (ปานกลาง)</option>
      <option value="hard">🟥 Hard (ยาก)</option>
    </select>
  );
}

function PreviewCard({
  preview,
  category,
  creator,
  onRefresh,
  onSave,
  creatorStatus
}: {
  preview: PreviewWord | null;
  category?: Category;
  creator: FallbackWord;
  onRefresh: () => void;
  onSave: () => void;
  creatorStatus?: string;
}) {
  const shadowColor = category?.color ? `${category.color}15` : '#6366F115';
  const themeColor = category?.color ?? '#4F46E5';

  const isGenerating = creatorStatus === 'Creating preview...' || creatorStatus === 'Refreshing image...';

  return (
    <div
      className="bg-white rounded-3xl border-2 p-5 shadow-lg transition-all duration-300 relative overflow-hidden"
      style={{
        borderColor: themeColor,
        boxShadow: `0 20px 25px -5px ${shadowColor}, 0 8px 10px -6px ${shadowColor}`
      }}
    >
      <div className="absolute top-0 right-0 w-24 h-24 rounded-bl-full opacity-10" style={{ backgroundColor: themeColor }}></div>

      <div className="flex items-center justify-between gap-3 mb-4">
        <div>
          <span className="text-[10px] font-extrabold tracking-wider text-slate-400 uppercase">Sticker Preview</span>
          <h3 className="text-xl font-black text-slate-900 tracking-tight leading-tight">{preview?.word || creator.word || 'Word Output'}</h3>
          <p className="text-xs font-semibold text-slate-500 mt-0.5">
            {category?.label ?? 'Category'} · <span className="text-indigo-600 font-mono">({preview?.phonetic || creator.phonetic || 'phonetic'})</span>
          </p>
        </div>
        <span className={`text-[10px] font-extrabold rounded-full px-2.5 py-1 uppercase border ${difficultyClasses[preview?.difficulty || creator.difficulty]}`}>
          {preview?.difficulty || creator.difficulty}
        </span>
      </div>

      {/* Card Body */}
      <div className="aspect-video relative overflow-hidden rounded-2xl bg-slate-50 border border-slate-100 flex items-center justify-center mb-4 group shadow-inner">
        {isGenerating ? (
          <div className="flex flex-col items-center gap-2.5">
            <RefreshCcw className="animate-spin text-indigo-600" size={28} />
            <span className="text-xs font-bold text-slate-500">Finding Sticker Image...</span>
          </div>
        ) : preview?.imageUrl || creator.imageUrl ? (
          <div className="relative w-full h-full flex items-center justify-center">
            <img
              src={preview?.imageUrl || creator.imageUrl || ''}
              alt={preview?.word || creator.word}
              className="w-full h-full object-contain p-2 hover:scale-105 transition-all duration-300"
            />
            {preview?.imageError && (
              <div className="absolute bottom-0 left-0 right-0 bg-amber-50/95 border-t border-amber-200 px-3 py-1.5 text-center">
                <span className="text-[10px] font-extrabold text-amber-700 block">
                  ⚠️ {preview.imageError}
                </span>
              </div>
            )}
          </div>
        ) : preview?.imageError ? (
          <div className="flex flex-col items-center text-red-500 p-4 text-center select-none">
            <span className="text-xs font-bold text-red-650 mb-1 flex items-center gap-1">⚠️ แจ้งเตือนระบบสร้างรูปภาพ</span>
            <p className="text-[11px] text-red-500 max-w-xs leading-normal font-bold text-center mt-1">{preview.imageError}</p>
          </div>
        ) : (
          <div className="flex flex-col items-center text-slate-400 p-6 text-center select-none">
            <ImageIconLucide size={36} className="opacity-40 mb-1.5" />
            <span className="text-xs font-bold text-slate-600">No Image Selected</span>
            <p className="text-[10px] text-slate-500 max-w-xs mt-0.5 leading-normal">Use Find Sticker Image below to search for a kid-friendly sticker image.</p>
          </div>
        )}
      </div>

      <div className="space-y-4">
        <div className="bg-slate-50 border border-slate-100 rounded-xl p-3 text-xs">
          <span className="font-bold text-slate-600 uppercase text-[9px] tracking-wider block mb-0.5">Thai translation</span>
          <p className="font-semibold text-slate-800 text-sm">{preview?.thaiMeaning || creator.thaiMeaning || 'Waiting translation...'}</p>
        </div>

        <div className="flex gap-2">
          <button
            onClick={onRefresh}
            disabled={!preview?.word && !creator.word.trim()}
            className="btn-white flex-1 flex items-center justify-center gap-1.5 rounded-xl py-2.5 text-xs font-bold shadow-sm hover:shadow-slate-100 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <RefreshCcw size={14} />
            Refresh Image
          </button>
          
          <button
            onClick={onSave}
            disabled={!creator.word.trim()}
            className="btn-primary flex-1 flex items-center justify-center gap-1.5 rounded-xl py-2.5 text-xs font-extrabold text-white shadow-md hover:shadow-indigo-100 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
            style={{ backgroundColor: themeColor, borderColor: themeColor }}
          >
            <Check size={14} />
            Save Word
          </button>
        </div>
      </div>
    </div>
  );
}

function CategoryRow({ category, showAdvanced, onSave, onDelete }: { category: Category; showAdvanced: boolean; onSave: (category: Category) => void; onDelete: () => void }) {
  const [draft, setDraft] = useState(() => normalizeCategoryIcon(category));

  useEffect(() => {
    setDraft(normalizeCategoryIcon(category));
  }, [category]);

  return (
    <tr className="hover:bg-slate-50/30">
      {showAdvanced && (
        <td className="px-4 py-2"><input value={draft.slug} onChange={(e) => setDraft({ ...draft, slug: e.target.value })} className="w-full rounded-lg border border-slate-200 px-2.5 py-1.5 font-semibold focus:border-indigo-500 outline-none" /></td>
      )}
      <td className="px-4 py-2"><input value={draft.label} onChange={(e) => setDraft({ ...draft, label: e.target.value })} className="w-full rounded-lg border border-slate-200 px-2.5 py-1.5 font-semibold focus:border-indigo-500 outline-none" /></td>
      <td className="px-4 py-2"><input value={draft.thaiLabel ?? ''} onChange={(e) => setDraft({ ...draft, thaiLabel: e.target.value })} className="w-full rounded-lg border border-slate-200 px-2.5 py-1.5 font-semibold focus:border-indigo-500 outline-none" /></td>
      {showAdvanced && (
        <>
          <td className="px-4 py-2"><EmojiInput value={draft.icon ?? ''} onChange={(icon) => setDraft({ ...draft, icon })} compact /></td>
          <td className="px-4 py-2"><input value={draft.color ?? ''} onChange={(e) => setDraft({ ...draft, color: e.target.value })} className="w-full rounded-lg border border-slate-200 px-2.5 py-1.5 font-semibold focus:border-indigo-500 outline-none" /></td>
          <td className="px-4 py-2"><input value={draft.sortOrder} onChange={(e) => setDraft({ ...draft, sortOrder: Number(e.target.value) || 0 })} className="w-20 rounded-lg border border-slate-200 px-2.5 py-1.5 font-semibold focus:border-indigo-500 outline-none" /></td>
        </>
      )}
      <td className="px-4 py-2"><input type="checkbox" checked={draft.active} onChange={(e) => setDraft({ ...draft, active: e.target.checked })} className="rounded text-indigo-600 focus:ring-indigo-500 w-4 h-4" /></td>
      <td className="px-4 py-2">
        <div className="flex gap-2 justify-center">
          <button onClick={() => onSave(draft)} className="p-2 bg-slate-50 hover:bg-slate-100 rounded-lg border border-slate-200 text-slate-700 transition-all duration-150"><Save size={14} /></button>
          <button onClick={onDelete} className="p-2 bg-red-50 hover:bg-red-100 rounded-lg border border-red-100 text-red-600 transition-all duration-150"><Trash2 size={14} /></button>
        </div>
      </td>
    </tr>
  );
}

function WordRow({
  word,
  categories,
  onSave,
  onFindImage,
  onDelete
}: {
  word: FallbackWord;
  categories: Category[];
  onSave: (word: FallbackWord) => void;
  onFindImage: (word: FallbackWord) => Promise<string>;
  onDelete: () => void;
}) {
  const [draft, setDraft] = useState(word);
  const [findingImage, setFindingImage] = useState(false);

  async function findStickerImage() {
    if (!draft.word.trim() || findingImage) return;
    setFindingImage(true);
    try {
      const imageUrl = await onFindImage(draft);
      if (imageUrl) setDraft((prev) => ({ ...prev, imageUrl }));
    } finally {
      setFindingImage(false);
    }
  }
  
  return (
    <div className="bg-white rounded-2xl border border-slate-200/80 p-4 shadow-sm hover:shadow-md hover:scale-[1.01] transition-all duration-200 flex flex-col justify-between">
      <div>
        <div className="flex items-center gap-3 mb-3">
          <div className="h-16 w-20 shrink-0 overflow-hidden rounded-xl bg-slate-50 border border-slate-100 flex items-center justify-center shadow-inner">
            {draft.imageUrl ? (
              <img src={draft.imageUrl} alt={draft.word} className="h-full w-full object-contain p-1" />
            ) : (
              <ImageIcon size={20} className="text-slate-400" />
            )}
          </div>
          <div className="min-w-0 flex-1">
            <input value={draft.word} onChange={(e) => setDraft({ ...draft, word: e.target.value })} className="w-full rounded-lg border border-slate-200 px-2 py-1 text-sm font-extrabold focus:border-indigo-500 outline-none" />
            <div className="mt-1">
              <span className={`text-[10px] font-extrabold rounded-full px-2 py-0.5 uppercase border ${difficultyClasses[draft.difficulty]}`}>{draft.difficulty}</span>
            </div>
          </div>
        </div>

        <div className="space-y-2 mb-3">
          <div className="grid grid-cols-2 gap-2">
            <select value={draft.categoryId} onChange={(e) => setDraft({ ...draft, categoryId: e.target.value })} className="w-full rounded-lg border border-slate-200 px-2 py-1 text-xs font-semibold outline-none bg-slate-50/50">
              {categories.map((c) => <option key={c.id} value={c.id}>{c.label}</option>)}
            </select>
            <select value={draft.difficulty} onChange={(e) => setDraft({ ...draft, difficulty: e.target.value as Difficulty })} className="w-full rounded-lg border border-slate-200 px-2 py-1 text-xs font-semibold outline-none bg-slate-50/50">
              <option value="easy">Easy</option>
              <option value="medium">Medium</option>
              <option value="hard">Hard</option>
            </select>
          </div>

          <input value={draft.thaiMeaning ?? ''} onChange={(e) => setDraft({ ...draft, thaiMeaning: e.target.value })} placeholder="Thai translation" className="w-full rounded-lg border border-slate-200 px-2 py-1 text-xs font-medium focus:border-indigo-500 outline-none" />
          <input value={draft.phonetic ?? ''} onChange={(e) => setDraft({ ...draft, phonetic: e.target.value })} placeholder="Phonetics guide" className="w-full rounded-lg border border-slate-200 px-2 py-1 text-xs font-mono font-medium focus:border-indigo-500 outline-none" />
          <input value={draft.imageUrl ?? ''} onChange={(e) => setDraft({ ...draft, imageUrl: e.target.value })} placeholder="Image base64 URL" className="w-full rounded-lg border border-slate-200 px-2 py-1 text-xs font-mono font-medium focus:border-indigo-500 outline-none" />
          <button
            type="button"
            onClick={findStickerImage}
            disabled={!draft.word.trim() || findingImage}
            className="w-full rounded-lg border border-indigo-100 bg-indigo-50 px-2 py-1.5 text-xs font-bold text-indigo-700 hover:bg-indigo-100 disabled:cursor-not-allowed disabled:opacity-50 transition-all duration-150 flex items-center justify-center gap-1.5"
            title={draft.imageUrl ? 'Refresh sticker image' : 'Find sticker image'}
          >
            {findingImage ? (
              <RefreshCcw size={13} className="animate-spin" />
            ) : (
              <Search size={13} />
            )}
            {findingImage ? 'Finding...' : draft.imageUrl ? 'Refresh Sticker Image' : 'Find Sticker Image'}
          </button>
        </div>
      </div>

      <div className="flex items-center justify-between border-t border-slate-50 pt-3 mt-1">
        <label className="text-[11px] font-bold text-slate-600 flex items-center gap-1.5 cursor-pointer">
          <input type="checkbox" checked={draft.active} onChange={(e) => setDraft({ ...draft, active: e.target.checked })} className="rounded text-indigo-600 focus:ring-indigo-500 w-3.5 h-3.5" />
          Active word
        </label>
        <div className="flex gap-1.5">
          <button onClick={() => onSave(draft)} className="p-1.5 bg-slate-50 hover:bg-slate-100 rounded-lg border border-slate-200 text-slate-700 transition-all duration-150" title="Save changes"><Save size={13} /></button>
          <button onClick={onDelete} className="p-1.5 bg-red-50 hover:bg-red-100 rounded-lg border border-red-100 text-red-600 transition-all duration-150" title="Delete word"><Trash2 size={13} /></button>
        </div>
      </div>
    </div>
  );
}

