'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { Ban, Plus, RefreshCcw, Save, Sparkles, Trash2 } from 'lucide-react';
import UserProfile from '@/components/UserProfile';

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
  active: true,
};

export default function AiWordGamePage() {
  const [data, setData] = useState<AdminData | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [newCategory, setNewCategory] = useState<Category>(emptyCategory);
  const [newWord, setNewWord] = useState<FallbackWord>(emptyWord);
  const [newBlockedTerm, setNewBlockedTerm] = useState('');
  const [testCategory, setTestCategory] = useState('');
  const [testResult, setTestResult] = useState<Record<string, unknown> | null>(null);

  const wordsByCategory = useMemo(() => {
    const map: Record<string, FallbackWord[]> = {};
    for (const word of data?.words ?? []) {
      map[word.categoryId] = [...(map[word.categoryId] ?? []), word];
    }
    return map;
  }, [data?.words]);

  const loadData = useCallback(async () => {
    setLoading(true);
    const res = await fetch('/api/admin/ai-word-game');
    const json = await res.json();
    setData(json);
    setTestCategory(json.categories?.[0]?.slug ?? '');
    setNewWord((prev) => ({
      ...prev,
      categoryId: json.categories?.[0]?.id ?? '',
    }));
    setLoading(false);
  }, []);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    loadData();
  }, [loadData]);

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

  async function runAction(payload: Record<string, unknown>) {
    await fetch('/api/admin/ai-word-game', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    await loadData();
  }

  async function testGenerate() {
    setTestResult(null);
    const res = await fetch('/api/dynamic-vocabulary', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ category: testCategory }),
    });
    setTestResult(await res.json());
    await loadData();
  }

  if (loading || !data) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="body-large-medium text-secondary--text">Loading...</div>
      </div>
    );
  }

  const { settings } = data;

  return (
    <div className="p-8">
      <div className="flex items-center justify-between mb-6">
        <div>
          <div className="body-small-regular text-secondary--text mb-1">
            AI Word Game &gt; Settings
          </div>
          <h1 className="heading-h3">AI WORD GAME</h1>
        </div>
        <UserProfile />
      </div>

      <section className="bg-white rounded-lg shadow p-5 mb-6">
        <div className="flex flex-wrap items-center justify-between gap-4 mb-5">
          <div>
            <h2 className="heading-h5">Display & Providers</h2>
            <p className="body-small-regular text-secondary--text">
              Controls whether the Voice Quest card appears in the Language activity list.
            </p>
          </div>
          <button
            onClick={saveSettings}
            disabled={saving}
            className="btn-primary px-4 py-2 rounded-lg flex items-center gap-2"
          >
            <Save size={18} />
            {saving ? 'Saving...' : 'Save Settings'}
          </button>
        </div>

        <div className="grid grid-cols-1 xl:grid-cols-3 gap-4">
          <label className="flex items-center gap-3 bg-gray--light1 rounded-lg p-3">
            <input
              type="checkbox"
              checked={settings.enabled}
              onChange={(e) => setData({ ...data, settings: { ...settings, enabled: e.target.checked } })}
            />
            <span className="body-medium-medium">Game enabled</span>
          </label>
          <label className="flex items-center gap-3 bg-gray--light1 rounded-lg p-3">
            <input
              type="checkbox"
              checked={settings.showInApp}
              onChange={(e) => setData({ ...data, settings: { ...settings, showInApp: e.target.checked } })}
            />
            <span className="body-medium-medium">Show card in app</span>
          </label>
          <label className="flex items-center gap-3 bg-gray--light1 rounded-lg p-3">
            <input
              type="checkbox"
              checked={settings.useGemini}
              onChange={(e) => setData({ ...data, settings: { ...settings, useGemini: e.target.checked } })}
            />
            <span className="body-medium-medium">Use Gemini</span>
          </label>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 mt-4">
          <TextInput label="Card title" value={settings.title} onChange={(title) => setData({ ...data, settings: { ...settings, title } })} />
          <TextInput label="Cover image URL" value={settings.coverImageUrl} onChange={(coverImageUrl) => setData({ ...data, settings: { ...settings, coverImageUrl } })} />
          <TextInput label="Gemini model" value={settings.geminiModel} onChange={(geminiModel) => setData({ ...data, settings: { ...settings, geminiModel } })} />
          <TextInput label="Image provider order" value={settings.imageProviderOrder} onChange={(imageProviderOrder) => setData({ ...data, settings: { ...settings, imageProviderOrder } })} />
          <TextInput label="Image query suffix" value={settings.imageQuerySuffix} onChange={(imageQuerySuffix) => setData({ ...data, settings: { ...settings, imageQuerySuffix } })} />
          <TextInput label="Max score" value={String(settings.maxScore)} onChange={(maxScore) => setData({ ...data, settings: { ...settings, maxScore: Number(maxScore) || 100 } })} />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 mt-4">
          <label className="flex items-center gap-3">
            <input type="checkbox" checked={settings.usePixabay} onChange={(e) => setData({ ...data, settings: { ...settings, usePixabay: e.target.checked } })} />
            Pixabay
          </label>
          <label className="flex items-center gap-3">
            <input type="checkbox" checked={settings.usePexels} onChange={(e) => setData({ ...data, settings: { ...settings, usePexels: e.target.checked } })} />
            Pexels
          </label>
        </div>

        <label className="block mt-4">
          <span className="body-small-medium text-secondary--text">Prompt template</span>
          <textarea
            value={settings.promptTemplate}
            onChange={(e) => setData({ ...data, settings: { ...settings, promptTemplate: e.target.value } })}
            className="w-full mt-1 px-3 py-2 border border-gray6 rounded-lg min-h-28"
          />
        </label>
      </section>

      <section className="bg-white rounded-lg shadow p-5 mb-6">
        <div className="flex flex-wrap items-end gap-3">
          <div>
            <h2 className="heading-h5">Test Generate</h2>
            <select value={testCategory} onChange={(e) => setTestCategory(e.target.value)} className="mt-2 px-3 py-2 border border-gray6 rounded-lg">
              {data.categories.filter((c) => c.active).map((category) => (
                <option key={category.id} value={category.slug}>{category.label}</option>
              ))}
            </select>
          </div>
          <button onClick={testGenerate} className="btn-primary px-4 py-2 rounded-lg flex items-center gap-2">
            <Sparkles size={18} />
            Test
          </button>
          {testResult && (
            <pre className="bg-gray--light1 rounded-lg p-3 text-xs overflow-auto max-w-full">
              {JSON.stringify(testResult, null, 2)}
            </pre>
          )}
        </div>
      </section>

      <section className="bg-white rounded-lg shadow p-5 mb-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="heading-h5">Categories</h2>
          <button
            onClick={() => runAction({ action: 'createCategory', ...newCategory })}
            className="btn-primary px-3 py-2 rounded-lg flex items-center gap-2"
          >
            <Plus size={16} />
            Add Category
          </button>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-6 gap-2 mb-3">
          <input placeholder="slug" value={newCategory.slug} onChange={(e) => setNewCategory({ ...newCategory, slug: e.target.value })} className="px-3 py-2 border border-gray6 rounded-lg" />
          <input placeholder="label" value={newCategory.label} onChange={(e) => setNewCategory({ ...newCategory, label: e.target.value })} className="px-3 py-2 border border-gray6 rounded-lg" />
          <input placeholder="Thai label" value={newCategory.thaiLabel ?? ''} onChange={(e) => setNewCategory({ ...newCategory, thaiLabel: e.target.value })} className="px-3 py-2 border border-gray6 rounded-lg" />
          <input placeholder="icon" value={newCategory.icon ?? ''} onChange={(e) => setNewCategory({ ...newCategory, icon: e.target.value })} className="px-3 py-2 border border-gray6 rounded-lg" />
          <input placeholder="#color" value={newCategory.color ?? ''} onChange={(e) => setNewCategory({ ...newCategory, color: e.target.value })} className="px-3 py-2 border border-gray6 rounded-lg" />
          <input placeholder="sort" value={newCategory.sortOrder} onChange={(e) => setNewCategory({ ...newCategory, sortOrder: Number(e.target.value) || 0 })} className="px-3 py-2 border border-gray6 rounded-lg" />
        </div>
        <div className="overflow-x-auto">
          <table className="w-full min-w-[900px]">
            <tbody className="divide-y divide-gray4">
              {data.categories.map((category) => (
                <CategoryRow key={category.id} category={category} onSave={(next) => runAction({ action: 'updateCategory', ...next })} onDelete={() => runAction({ action: 'deleteCategory', id: category.id })} />
              ))}
            </tbody>
          </table>
        </div>
      </section>

      <section className="bg-white rounded-lg shadow p-5 mb-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="heading-h5">Fallback Words</h2>
          <button onClick={() => runAction({ action: 'createWord', ...newWord })} className="btn-primary px-3 py-2 rounded-lg flex items-center gap-2">
            <Plus size={16} />
            Add Word
          </button>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-5 gap-2 mb-4">
          <select value={newWord.categoryId} onChange={(e) => setNewWord({ ...newWord, categoryId: e.target.value })} className="px-3 py-2 border border-gray6 rounded-lg">
            {data.categories.map((category) => <option key={category.id} value={category.id}>{category.label}</option>)}
          </select>
          <input placeholder="word" value={newWord.word} onChange={(e) => setNewWord({ ...newWord, word: e.target.value })} className="px-3 py-2 border border-gray6 rounded-lg" />
          <input placeholder="Thai meaning" value={newWord.thaiMeaning ?? ''} onChange={(e) => setNewWord({ ...newWord, thaiMeaning: e.target.value })} className="px-3 py-2 border border-gray6 rounded-lg" />
          <input placeholder="phonetic" value={newWord.phonetic ?? ''} onChange={(e) => setNewWord({ ...newWord, phonetic: e.target.value })} className="px-3 py-2 border border-gray6 rounded-lg" />
        </div>
        {data.categories.map((category) => (
          <div key={category.id} className="mb-4">
            <h3 className="body-medium-medium mb-2">{category.label}</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-2">
              {(wordsByCategory[category.id] ?? []).map((word) => (
                <WordRow key={word.id} word={word} categories={data.categories} onSave={(next) => runAction({ action: 'updateWord', ...next })} onDelete={() => runAction({ action: 'deleteWord', id: word.id })} />
              ))}
            </div>
          </div>
        ))}
      </section>

      <section className="bg-white rounded-lg shadow p-5 mb-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="heading-h5 flex items-center gap-2"><Ban size={18} /> Blocked Terms</h2>
          <button onClick={() => runAction({ action: 'createBlockedTerm', term: newBlockedTerm, active: true })} className="btn-primary px-3 py-2 rounded-lg">Add</button>
        </div>
        <input value={newBlockedTerm} onChange={(e) => setNewBlockedTerm(e.target.value)} placeholder="blocked word" className="px-3 py-2 border border-gray6 rounded-lg mb-3" />
        <div className="flex flex-wrap gap-2">
          {data.blockedTerms.map((term) => (
            <button key={term.id} onClick={() => runAction({ action: 'deleteBlockedTerm', id: term.id })} className="px-3 py-1 rounded-full bg-red--light6 text-red--dark body-small-medium">
              {term.term} ×
            </button>
          ))}
        </div>
      </section>

      <section className="bg-white rounded-lg shadow p-5">
        <div className="flex items-center justify-between mb-4">
          <h2 className="heading-h5">Generation Logs</h2>
          <button onClick={loadData} className="btn-white px-3 py-2 rounded-lg flex items-center gap-2">
            <RefreshCcw size={16} />
            Refresh
          </button>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full min-w-[760px]">
            <thead className="bg-gray--light1">
              <tr>
                <th className="px-3 py-2 text-left">Time</th>
                <th className="px-3 py-2 text-left">Category</th>
                <th className="px-3 py-2 text-left">Word</th>
                <th className="px-3 py-2 text-left">Source</th>
                <th className="px-3 py-2 text-left">Image</th>
                <th className="px-3 py-2 text-left">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray4">
              {data.logs.map((log) => (
                <tr key={log.id}>
                  <td className="px-3 py-2 body-small-regular">{new Date(log.createdAt).toLocaleString()}</td>
                  <td className="px-3 py-2">{log.categorySlug}</td>
                  <td className="px-3 py-2">{log.word ?? '-'}</td>
                  <td className="px-3 py-2">{log.wordSource ?? '-'}</td>
                  <td className="px-3 py-2">{log.imageSource ?? '-'}</td>
                  <td className="px-3 py-2">{log.status}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}

function TextInput({ label, value, onChange }: { label: string; value: string; onChange: (value: string) => void }) {
  return (
    <label className="block">
      <span className="body-small-medium text-secondary--text">{label}</span>
      <input value={value} onChange={(e) => onChange(e.target.value)} className="w-full mt-1 px-3 py-2 border border-gray6 rounded-lg" />
    </label>
  );
}

function CategoryRow({ category, onSave, onDelete }: { category: Category; onSave: (category: Category) => void; onDelete: () => void }) {
  const [draft, setDraft] = useState(category);
  return (
    <tr>
      <td className="px-2 py-2"><input value={draft.slug} onChange={(e) => setDraft({ ...draft, slug: e.target.value })} className="w-full px-2 py-1 border rounded" /></td>
      <td className="px-2 py-2"><input value={draft.label} onChange={(e) => setDraft({ ...draft, label: e.target.value })} className="w-full px-2 py-1 border rounded" /></td>
      <td className="px-2 py-2"><input value={draft.thaiLabel ?? ''} onChange={(e) => setDraft({ ...draft, thaiLabel: e.target.value })} className="w-full px-2 py-1 border rounded" /></td>
      <td className="px-2 py-2"><input value={draft.icon ?? ''} onChange={(e) => setDraft({ ...draft, icon: e.target.value })} className="w-full px-2 py-1 border rounded" /></td>
      <td className="px-2 py-2"><input value={draft.color ?? ''} onChange={(e) => setDraft({ ...draft, color: e.target.value })} className="w-full px-2 py-1 border rounded" /></td>
      <td className="px-2 py-2"><input value={draft.sortOrder} onChange={(e) => setDraft({ ...draft, sortOrder: Number(e.target.value) || 0 })} className="w-20 px-2 py-1 border rounded" /></td>
      <td className="px-2 py-2"><input type="checkbox" checked={draft.active} onChange={(e) => setDraft({ ...draft, active: e.target.checked })} /></td>
      <td className="px-2 py-2">
        <div className="flex gap-2">
          <button onClick={() => onSave(draft)} className="btn-white p-2 rounded"><Save size={15} /></button>
          <button onClick={onDelete} className="text-red--dark p-2"><Trash2 size={15} /></button>
        </div>
      </td>
    </tr>
  );
}

function WordRow({ word, categories, onSave, onDelete }: { word: FallbackWord; categories: Category[]; onSave: (word: FallbackWord) => void; onDelete: () => void }) {
  const [draft, setDraft] = useState(word);
  return (
    <div className="border border-gray4 rounded-lg p-3">
      <select value={draft.categoryId} onChange={(e) => setDraft({ ...draft, categoryId: e.target.value })} className="w-full px-2 py-1 border rounded mb-2">
        {categories.map((category) => <option key={category.id} value={category.id}>{category.label}</option>)}
      </select>
      <input value={draft.word} onChange={(e) => setDraft({ ...draft, word: e.target.value })} className="w-full px-2 py-1 border rounded mb-2" />
      <input value={draft.thaiMeaning ?? ''} onChange={(e) => setDraft({ ...draft, thaiMeaning: e.target.value })} className="w-full px-2 py-1 border rounded mb-2" />
      <input value={draft.phonetic ?? ''} onChange={(e) => setDraft({ ...draft, phonetic: e.target.value })} className="w-full px-2 py-1 border rounded mb-2" />
      <div className="flex items-center justify-between">
        <label className="flex items-center gap-2 body-small-regular">
          <input type="checkbox" checked={draft.active} onChange={(e) => setDraft({ ...draft, active: e.target.checked })} />
          Active
        </label>
        <div className="flex gap-2">
          <button onClick={() => onSave(draft)} className="btn-white p-2 rounded"><Save size={15} /></button>
          <button onClick={onDelete} className="text-red--dark p-2"><Trash2 size={15} /></button>
        </div>
      </div>
    </div>
  );
}
