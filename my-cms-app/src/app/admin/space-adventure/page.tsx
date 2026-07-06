'use client';

import { useState, useEffect } from 'react';
import { Edit2, ImageIcon, Map, Plus, Rocket, Save, Trash2, Trophy, RefreshCw, Settings, Upload } from 'lucide-react';
import UserProfile from '@/components/UserProfile';

interface GameSetting {
  id: string;
  scorePerItem: number;
  timerLimit: number;
  updatedAt: string;
}

interface GameScore {
  id: string;
  playerName: string;
  score: number;
  createdAt: string;
}

interface SpaceAdventureArea {
  id: string;
  name: string;
  imageUrl: string;
  items: string[];
  active: boolean;
  sortOrder: number;
}

const emptyAreaForm = {
  id: '',
  name: '',
  imageUrl: '',
  itemsText: '',
  active: true,
  sortOrder: 0,
};

export default function SpaceAdventureAdminPage() {
  const [settings, setSettings] = useState<GameSetting | null>(null);
  const [scores, setScores] = useState<GameScore[]>([]);
  const [areas, setAreas] = useState<SpaceAdventureArea[]>([]);
  const [areaForm, setAreaForm] = useState(emptyAreaForm);
  const [scorePerItemInput, setScorePerItemInput] = useState<number>(10);
  const [timerLimitInput, setTimerLimitInput] = useState<number>(60);
  const [loading, setLoading] = useState<boolean>(true);
  const [saveStatus, setSaveStatus] = useState<'idle' | 'saving' | 'success' | 'error'>('idle');
  const [areaStatus, setAreaStatus] = useState<'idle' | 'saving' | 'success' | 'error'>('idle');
  const [areaError, setAreaError] = useState<string>('');
  const [imageUploadStatus, setImageUploadStatus] = useState<'idle' | 'uploading' | 'error'>('idle');

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);
    try {
      const settingsRes = await fetch('/api/space-adventure/settings');
      const settingsData = await settingsRes.json();
      if (settingsData.success && settingsData.data) {
        setSettings(settingsData.data);
        setScorePerItemInput(settingsData.data.scorePerItem);
        setTimerLimitInput(settingsData.data.timerLimit);
      }

      const scoresRes = await fetch('/api/space-adventure/score');
      const scoresData = await scoresRes.json();
      if (scoresData.success && scoresData.scores) {
        setScores(scoresData.scores);
      }

      const areasRes = await fetch('/api/space-adventure/areas');
      const areasData = await areasRes.json();
      if (areasData.success && areasData.areas) {
        setAreas(areasData.areas);
      }
    } catch (error) {
      console.error('Error fetching Space Adventure CMS data:', error);
    } finally {
      setLoading(false);
    }
  };

  const resetAreaForm = () => {
    setAreaForm(emptyAreaForm);
    setAreaStatus('idle');
    setAreaError('');
  };

  const editArea = (area: SpaceAdventureArea) => {
    setAreaForm({
      id: area.id,
      name: area.name,
      imageUrl: area.imageUrl,
      itemsText: area.items.join(', '),
      active: area.active,
      sortOrder: area.sortOrder,
    });
    setAreaStatus('idle');
    setAreaError('');
  };

  const handleSaveArea = async (e: React.FormEvent) => {
    e.preventDefault();
    setAreaStatus('saving');
    setAreaError('');
    try {
      const response = await fetch('/api/space-adventure/areas', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          id: areaForm.id || undefined,
          name: areaForm.name,
          imageUrl: areaForm.imageUrl,
          items: areaForm.itemsText.split(',').map((item) => item.trim()).filter(Boolean),
          active: areaForm.active,
          sortOrder: areaForm.sortOrder,
        }),
      });
      const data = await response.json();
      if (!data.success) throw new Error(data.error || 'Failed to save area.');
      setAreaStatus('success');
      resetAreaForm();
      await fetchData();
    } catch (error: unknown) {
      setAreaError(error instanceof Error ? error.message : 'Failed to save area.');
      setAreaStatus('error');
    }
  };

  const handleAreaImageUpload = async (file: File | null) => {
    if (!file) return;
    setImageUploadStatus('uploading');
    setAreaError('');
    try {
      const formData = new FormData();
      formData.append('image', file);
      const response = await fetch('/api/space-adventure/area-image', {
        method: 'POST',
        body: formData,
      });
      const data = await response.json();
      if (!data.success || !data.imageUrl) {
        throw new Error(data.error || 'Failed to upload image.');
      }
      setAreaForm((current) => ({ ...current, imageUrl: data.imageUrl }));
      setImageUploadStatus('idle');
    } catch (error: unknown) {
      setAreaError(error instanceof Error ? error.message : 'Failed to upload image.');
      setAreaStatus('error');
      setImageUploadStatus('error');
    }
  };

  const handleDeleteArea = async (id: string) => {
    if (!window.confirm('Delete this Space Adventure area?')) return;
    try {
      const response = await fetch(`/api/space-adventure/areas?id=${encodeURIComponent(id)}`, {
        method: 'DELETE',
      });
      const data = await response.json();
      if (!data.success) throw new Error(data.error || 'Failed to delete area.');
      if (areaForm.id === id) resetAreaForm();
      await fetchData();
    } catch (error: unknown) {
      setAreaError(error instanceof Error ? error.message : 'Failed to delete area.');
      setAreaStatus('error');
    }
  };

  const handleSaveSettings = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaveStatus('saving');
    try {
      const response = await fetch('/api/space-adventure/settings', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          scorePerItem: scorePerItemInput,
          timerLimit: timerLimitInput,
        }),
      });
      const data = await response.json();
      if (data.success) {
        setSettings(data.data);
        setSaveStatus('success');
        setTimeout(() => setSaveStatus('idle'), 3000);
      } else {
        setSaveStatus('error');
      }
    } catch (error) {
      console.error('Error saving Space Adventure settings:', error);
      setSaveStatus('error');
    }
  };

  return (
    <div className="min-h-screen bg-gray--light1 p-6 lg:p-8">
      {/* Top Header */}
      <header className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8 border-b border-gray4 pb-6">
        <div>
          <div className="flex items-center gap-3">
            <div className="p-2.5 bg-purple--light5 text-purple rounded-xl">
              <Rocket className="w-8 height-8 animate-bounce" />
            </div>
            <div>
              <h1 className="text-3xl font-extrabold text-dark tracking-tight">Space Adventure</h1>
              <p className="text-sm text-secondary--text mt-1">Manage AI vision object scavenger hunt configuration and leaderboard.</p>
            </div>
          </div>
        </div>
        <div className="flex items-center gap-4">
          <button
            onClick={fetchData}
            className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-purple bg-purple--light5 hover:bg-purple--light6 transition rounded-lg border border-purple--light3"
          >
            <RefreshCw className="w-4 h-4" />
            Refresh Dashboard
          </button>
          <UserProfile />
        </div>
      </header>

      {loading ? (
        <div className="flex items-center justify-center py-20">
          <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-purple"></div>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          
          {/* Settings Section */}
          <div className="lg:col-span-1 flex flex-col gap-6">
            <div className="bg-white rounded-2xl border border-gray4 shadow-sm overflow-hidden">
              <div className="p-5 border-b border-gray4 flex items-center gap-2.5 bg-gray--light1">
                <Settings className="w-5 h-5 text-purple" />
                <h2 className="text-lg font-bold text-dark">Gameplay settings</h2>
              </div>
              
              <form onSubmit={handleSaveSettings} className="p-6 flex flex-col gap-5">
                <div>
                  <label className="block text-sm font-semibold text-primary--text mb-2">
                    Score per Correct Item
                  </label>
                  <input
                    type="number"
                    min="1"
                    max="1000"
                    value={scorePerItemInput}
                    onChange={(e) => setScorePerItemInput(Number(e.target.value))}
                    className="w-full px-4 py-3 rounded-xl border border-gray4 focus:outline-none focus:ring-2 focus:ring-purple focus:border-transparent transition text-dark"
                    required
                  />
                  <p className="text-xs text-secondary--text mt-1.5">
                    How many points a player receives for a verified correct camera match.
                  </p>
                </div>

                <div>
                  <label className="block text-sm font-semibold text-primary--text mb-2">
                    Countdown Timer Limit (seconds)
                  </label>
                  <input
                    type="number"
                    min="10"
                    max="600"
                    value={timerLimitInput}
                    onChange={(e) => setTimerLimitInput(Number(e.target.value))}
                    className="w-full px-4 py-3 rounded-xl border border-gray4 focus:outline-none focus:ring-2 focus:ring-purple focus:border-transparent transition text-dark"
                    required
                  />
                  <p className="text-xs text-secondary--text mt-1.5">
                    Scavenger search duration countdown limit per item in seconds.
                  </p>
                </div>

                <div className="border-t border-gray4 pt-4 mt-2 flex flex-col gap-3">
                  <button
                    type="submit"
                    disabled={saveStatus === 'saving'}
                    className="w-full flex items-center justify-center gap-2 bg-purple hover:bg-purple--dark text-white font-semibold py-3 px-4 rounded-xl transition shadow-md disabled:opacity-50"
                  >
                    <Save className="w-4 h-4" />
                    {saveStatus === 'saving' ? 'Saving settings...' : 'Save Configuration'}
                  </button>

                  {saveStatus === 'success' && (
                    <div className="p-3 text-center text-sm text-green bg-green--light6 border border-green rounded-xl">
                      Settings updated successfully!
                    </div>
                  )}

                  {saveStatus === 'error' && (
                    <div className="p-3 text-center text-sm text-red bg-red--light6 border border-red rounded-xl">
                      Failed to save settings. Please try again.
                    </div>
                  )}
                </div>
              </form>
            </div>
            
            {/* Game Card preview */}
            <div className="bg-gradient-to-br from-indigo-900 to-purple-800 text-white rounded-2xl p-6 shadow-lg border border-purple--dark flex flex-col gap-4 relative overflow-hidden">
              <div className="absolute right-[-20px] top-[-20px] opacity-15">
                <Rocket className="w-40 h-40 transform rotate-45" />
              </div>
              <span className="self-start px-3 py-1 bg-white/20 backdrop-blur-sm rounded-full text-xs font-bold tracking-wider">
                SPACE ADVENTURE APP
              </span>
              <h3 className="text-2xl font-black mt-2">Ready for Lift Off!</h3>
              <p className="text-sm text-purple--light5 leading-relaxed">
                Configure your scavenger hunt points and timer values here. The Flutter app will dynamically adapt to these settings in real-time.
              </p>
              <div className="grid grid-cols-2 gap-4 mt-4 bg-white/10 backdrop-blur-md rounded-xl p-4">
                <div>
                  <p className="text-xs text-purple--light3">Points per item</p>
                  <p className="text-xl font-extrabold">{settings?.scorePerItem ?? 10} pts</p>
                </div>
                <div>
                  <p className="text-xs text-purple--light3">Time Hunt limit</p>
                  <p className="text-xl font-extrabold">{settings?.timerLimit ?? 60} sec</p>
                </div>
              </div>
            </div>
          </div>

          <div className="lg:col-span-2 flex flex-col gap-8">
            {/* Areas Section */}
            <div className="bg-white rounded-2xl border border-gray4 shadow-sm overflow-hidden">
              <div className="p-5 border-b border-gray4 flex items-center justify-between bg-gray--light1">
                <div className="flex items-center gap-2.5">
                  <Map className="w-5 h-5 text-purple" />
                  <h2 className="text-lg font-bold text-dark">Playable areas</h2>
                </div>
                <span className="text-xs font-semibold text-secondary--text bg-gray4 px-3 py-1 rounded-full">
                  {areas.length} areas
                </span>
              </div>

              <div className="grid grid-cols-1 xl:grid-cols-5 gap-0">
                <form onSubmit={handleSaveArea} className="xl:col-span-2 p-6 border-b xl:border-b-0 xl:border-r border-gray4 flex flex-col gap-4">
                  <div>
                    <label className="block text-sm font-semibold text-primary--text mb-2">
                      Area name
                    </label>
                    <input
                      value={areaForm.name}
                      onChange={(e) => setAreaForm({ ...areaForm, name: e.target.value })}
                      placeholder="Area name"
                      className="w-full px-4 py-3 rounded-xl border border-gray4 focus:outline-none focus:ring-2 focus:ring-purple text-dark"
                      required
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-semibold text-primary--text mb-2">
                      Area image
                    </label>
                    <label className="flex flex-col items-center justify-center gap-3 rounded-xl border-2 border-dashed border-gray4 bg-gray--light1 px-4 py-5 text-center cursor-pointer hover:border-purple transition">
                      {areaForm.imageUrl ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img src={areaForm.imageUrl} alt="Area preview" className="h-32 w-full rounded-lg object-cover" />
                      ) : (
                        <div className="flex h-24 w-full items-center justify-center rounded-lg bg-white text-secondary--text">
                          <ImageIcon className="w-8 h-8" />
                        </div>
                      )}
                      <span className="inline-flex items-center gap-2 text-sm font-semibold text-purple">
                        <Upload className="w-4 h-4" />
                        {imageUploadStatus === 'uploading' ? 'Uploading to MinIO...' : 'Upload image from computer'}
                      </span>
                      <input
                        type="file"
                        accept="image/jpeg,image/png,image/webp"
                        className="hidden"
                        disabled={imageUploadStatus === 'uploading'}
                        onChange={(e) => {
                          void handleAreaImageUpload(e.target.files?.[0] ?? null);
                          e.target.value = '';
                        }}
                      />
                    </label>
                    {areaForm.imageUrl && (
                      <button
                        type="button"
                        onClick={() => setAreaForm({ ...areaForm, imageUrl: '' })}
                        className="mt-2 text-xs font-semibold text-red hover:underline"
                      >
                        Remove image
                      </button>
                    )}
                  </div>

                  <div>
                    <label className="block text-sm font-semibold text-primary--text mb-2">
                      Items in this area
                    </label>
                    <textarea
                      value={areaForm.itemsText}
                      onChange={(e) => setAreaForm({ ...areaForm, itemsText: e.target.value })}
                      placeholder="pillow, chair, bed, book, toy, bottle, cup"
                      rows={4}
                      className="w-full px-4 py-3 rounded-xl border border-gray4 focus:outline-none focus:ring-2 focus:ring-purple text-dark"
                      required
                    />
                    <p className="text-xs text-secondary--text mt-1.5">
                      Separate each target word with a comma. These words appear when a child chooses this area.
                    </p>
                  </div>

                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="block text-sm font-semibold text-primary--text mb-2">
                        Sort order
                      </label>
                      <input
                        type="number"
                        value={areaForm.sortOrder}
                        onChange={(e) => setAreaForm({ ...areaForm, sortOrder: Number(e.target.value) || 0 })}
                        className="w-full px-4 py-3 rounded-xl border border-gray4 focus:outline-none focus:ring-2 focus:ring-purple text-dark"
                      />
                    </div>
                    <label className="flex items-center gap-3 mt-8 text-sm font-semibold text-primary--text">
                      <input
                        type="checkbox"
                        checked={areaForm.active}
                        onChange={(e) => setAreaForm({ ...areaForm, active: e.target.checked })}
                        className="w-4 h-4 rounded text-purple focus:ring-purple"
                      />
                      Active
                    </label>
                  </div>

                  <div className="flex gap-3">
                    <button
                      type="submit"
                      disabled={areaStatus === 'saving'}
                      className="flex-1 flex items-center justify-center gap-2 bg-purple hover:bg-purple--dark text-white font-semibold py-3 px-4 rounded-xl transition disabled:opacity-50"
                    >
                      {areaForm.id ? <Save className="w-4 h-4" /> : <Plus className="w-4 h-4" />}
                      {areaStatus === 'saving' ? 'Saving...' : areaForm.id ? 'Update Area' : 'Add Area'}
                    </button>
                    {areaForm.id && (
                      <button
                        type="button"
                        onClick={resetAreaForm}
                        className="px-4 py-3 rounded-xl border border-gray4 text-sm font-semibold text-primary--text hover:bg-gray--light1"
                      >
                        Cancel
                      </button>
                    )}
                  </div>

                  {areaStatus === 'success' && (
                    <div className="p-3 text-center text-sm text-green bg-green--light6 border border-green rounded-xl">
                      Area saved successfully.
                    </div>
                  )}

                  {areaStatus === 'error' && (
                    <div className="p-3 text-center text-sm text-red bg-red--light6 border border-red rounded-xl">
                      {areaError || 'Failed to save area.'}
                    </div>
                  )}
                </form>

                <div className="xl:col-span-3 p-6">
                  {areas.length === 0 ? (
                    <div className="p-10 text-center text-secondary--text border border-dashed border-gray4 rounded-2xl">
                      <ImageIcon className="w-12 h-12 mx-auto mb-3 text-gray6" />
                      <p className="font-bold">No areas yet</p>
                      <p className="text-sm mt-1">Add any space children can explore, then choose target items for that area.</p>
                    </div>
                  ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {areas.map((area) => (
                        <div key={area.id} className="border border-gray4 rounded-2xl overflow-hidden bg-gray--light1/40">
                          <div className="h-36 bg-gray4 relative">
                            {area.imageUrl ? (
                              // eslint-disable-next-line @next/next/no-img-element
                              <img src={area.imageUrl} alt={area.name} className="w-full h-full object-cover" />
                            ) : (
                              <div className="h-full flex items-center justify-center text-secondary--text">
                                <ImageIcon className="w-10 h-10" />
                              </div>
                            )}
                            <span className={`absolute top-3 left-3 px-2.5 py-1 rounded-full text-xs font-bold ${area.active ? 'bg-green--light6 text-green' : 'bg-gray4 text-secondary--text'}`}>
                              {area.active ? 'Active' : 'Hidden'}
                            </span>
                          </div>
                          <div className="p-4">
                            <div className="flex items-start justify-between gap-3">
                              <div>
                                <h3 className="font-extrabold text-dark">{area.name}</h3>
                                <p className="text-xs text-secondary--text mt-1">Sort order: {area.sortOrder}</p>
                              </div>
                              <div className="flex gap-2">
                                <button
                                  type="button"
                                  onClick={() => editArea(area)}
                                  className="p-2 rounded-lg border border-gray4 bg-white hover:bg-gray--light1 text-purple"
                                  aria-label={`Edit ${area.name}`}
                                >
                                  <Edit2 className="w-4 h-4" />
                                </button>
                                <button
                                  type="button"
                                  onClick={() => handleDeleteArea(area.id)}
                                  className="p-2 rounded-lg border border-gray4 bg-white hover:bg-red--light6 text-red"
                                  aria-label={`Delete ${area.name}`}
                                >
                                  <Trash2 className="w-4 h-4" />
                                </button>
                              </div>
                            </div>
                            <div className="flex flex-wrap gap-2 mt-4">
                              {area.items.map((item) => (
                                <span key={item} className="px-2.5 py-1 rounded-full bg-white border border-purple--light4 text-purple text-xs font-bold">
                                  {item}
                                </span>
                              ))}
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* Leaderboard Section */}
            <div className="bg-white rounded-2xl border border-gray4 shadow-sm overflow-hidden">
              <div className="p-5 border-b border-gray4 flex items-center justify-between bg-gray--light1">
                <div className="flex items-center gap-2.5">
                  <Trophy className="w-5 h-5 text-yellow--light" />
                  <h2 className="text-lg font-bold text-dark">Space Adventure Leaderboard</h2>
                </div>
                <span className="text-xs font-semibold text-secondary--text bg-gray4 px-3 py-1 rounded-full">
                  Top {scores.length} Players
                </span>
              </div>

              {scores.length === 0 ? (
                <div className="p-12 text-center text-secondary--text">
                  <Trophy className="w-16 h-16 mx-auto mb-4 text-gray6" />
                  <p className="text-base font-bold">No scores recorded yet</p>
                  <p className="text-sm mt-1">Play the game on the mobile app to populate the leaderboard!</p>
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-left border-collapse">
                    <thead>
                      <tr className="border-b border-gray4 text-xs font-bold text-secondary--text bg-gray--light1/50 uppercase">
                        <th className="p-4 pl-6 w-16">Rank</th>
                        <th className="p-4">Player Name</th>
                        <th className="p-4">Score</th>
                        <th className="p-4 pr-6 text-right">Date Played</th>
                      </tr>
                    </thead>
                    <tbody>
                      {scores.map((score, index) => {
                        const rankColors = [
                          'bg-yellow--light3 text-yellow-800 border-yellow-300',
                          'bg-slate-100 text-slate-700 border-slate-300',
                          'bg-amber-100 text-amber-800 border-amber-300'
                        ];
                        const rankLabel = index < 3 ? (
                          <span className={`inline-flex items-center justify-center w-6 h-6 rounded-full font-bold text-xs border ${rankColors[index]}`}>
                            {index + 1}
                          </span>
                        ) : (
                          <span className="text-secondary--text font-medium text-sm pl-2">
                            {index + 1}
                          </span>
                        );
                        
                        return (
                          <tr key={score.id} className="border-b border-gray4 hover:bg-gray--light1/50 transition">
                            <td className="p-4 pl-6">{rankLabel}</td>
                            <td className="p-4 font-bold text-dark">{score.playerName}</td>
                            <td className="p-4">
                              <span className="inline-block px-3 py-1 bg-purple--light5 text-purple font-bold text-sm rounded-lg border border-purple--light4">
                                {score.score} pts
                              </span>
                            </td>
                            <td className="p-4 pr-6 text-right text-xs text-secondary--text">
                              {new Date(score.createdAt).toLocaleDateString(undefined, {
                                year: 'numeric',
                                month: 'short',
                                day: 'numeric',
                                hour: '2-digit',
                                minute: '2-digit',
                              })}
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
