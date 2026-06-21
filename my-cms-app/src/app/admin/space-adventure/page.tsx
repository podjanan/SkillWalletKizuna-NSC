'use client';

import { useState, useEffect } from 'react';
import { Rocket, Trophy, Settings, Save, RefreshCw } from 'lucide-react';
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

export default function SpaceAdventureAdminPage() {
  const [settings, setSettings] = useState<GameSetting | null>(null);
  const [scores, setScores] = useState<GameScore[]>([]);
  const [scorePerItemInput, setScorePerItemInput] = useState<number>(10);
  const [timerLimitInput, setTimerLimitInput] = useState<number>(60);
  const [loading, setLoading] = useState<boolean>(true);
  const [saveStatus, setSaveStatus] = useState<'idle' | 'saving' | 'success' | 'error'>('idle');

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
    } catch (error) {
      console.error('Error fetching Space Adventure CMS data:', error);
    } finally {
      setLoading(false);
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

          {/* Leaderboard Section */}
          <div className="lg:col-span-2">
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
