'use client';

import React, { useEffect, useState } from 'react';
import {
  Music,
  Sparkles,
  Play,
  Pause,
  Plus,
  Trash2,
  CheckCircle2,
  Guitar,
  Languages,
  BookOpen,
  Volume2,
  RefreshCw,
  Edit2,
  Save,
  Upload,
} from 'lucide-react';
import UserProfile from '@/components/UserProfile';

type LyricLine = {
  lineEn: string;
  lineTh: string;
  chord: string;
};

type TargetWord = {
  word: string;
  thaiMeaning: string;
  phonetic?: string;
};

type Song = {
  id: string;
  titleEn: string;
  titleTh: string;
  genre: string;
  targetWords: TargetWord[];
  lyrics: LyricLine[];
  audioUrl: string | null;
  coverUrl: string | null;
  isPublished: boolean;
  createdAt: string;
};

export default function BilingualSongsAdminPage() {
  const [songs, setSongs] = useState<Song[]>([]);
  const [loading, setLoading] = useState(true);

  // Form statesdocker compose up -d
  const [phrasesInput, setPhrasesInput] = useState('We can sing, We can play, Happy friends');
  const [genre, setGenre] = useState('Upbeat Nursery Rhyme');

  // Generated / Editing results
  const [generatedTitleEn, setGeneratedTitleEn] = useState('');
  const [generatedTitleTh, setGeneratedTitleTh] = useState('');
  const [generatedWords, setGeneratedWords] = useState<TargetWord[]>([]);
  const [generatedLyrics, setGeneratedLyrics] = useState<LyricLine[]>([]);
  const [generatedAudioUrl, setGeneratedAudioUrl] = useState('');

  // UI state
  const [isGeneratingLyrics, setIsGeneratingLyrics] = useState(false);
  const [isGeneratingAudio, setIsGeneratingAudio] = useState(false);
  const [isUploadingFile, setIsUploadingFile] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [editingSongId, setEditingSongId] = useState<string | null>(null);

  // Audio player state
  const [isPlaying, setIsPlaying] = useState(false);
  const [audioRef, setAudioRef] = useState<HTMLAudioElement | null>(null);
  const [bgAudioRef, setBgAudioRef] = useState<HTMLAudioElement | null>(null);

  const fetchSongs = async () => {
    try {
      setLoading(true);
      const res = await fetch('/api/admin/bilingual-songs');
      if (res.ok) {
        const data = await res.json();
        setSongs(data);
      }
    } catch (err) {
      console.error('Failed to fetch songs:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchSongs();
  }, []);

  const handleGenerateLyrics = async () => {
    if (!phrasesInput.trim()) return;
    setIsGeneratingLyrics(true);
    try {
      const res = await fetch('/api/admin/bilingual-songs', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'generateLyrics',
          phrases: phrasesInput,
          genre,
        }),
      });

      if (res.ok) {
        const data = await res.json();
        setGeneratedTitleEn(data.titleEn);
        setGeneratedTitleTh(data.titleTh);
        setGeneratedWords(data.targetWords || []);
        setGeneratedLyrics(data.lyrics || []);
      }
    } catch (e) {
      console.error('Lyric generation error:', e);
    } finally {
      setIsGeneratingLyrics(false);
    }
  };

  const handleGenerateAudio = async () => {
    if (generatedLyrics.length === 0) return;
    setIsGeneratingAudio(true);
    try {
      const res = await fetch('/api/admin/bilingual-songs', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'generateAudio',
          title: generatedTitleEn || 'Kids Song',
          lyrics: generatedLyrics,
          genre,
        }),
      });

      if (res.ok) {
        const data = await res.json();
        setGeneratedAudioUrl(data.audioUrl);
      }
    } catch (e) {
      console.error('Audio generation error:', e);
    } finally {
      setIsGeneratingAudio(false);
    }
  };

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setIsUploadingFile(true);
    try {
      const formData = new FormData();
      formData.append('file', file);

      const res = await fetch('/api/admin/bilingual-songs', {
        method: 'POST',
        body: formData,
      });

      if (res.ok) {
        const data = await res.json();
        setGeneratedAudioUrl(data.audioUrl);
      } else {
        alert('อัปโหลดไฟล์ไม่สำเร็จ โปรดลองอีกครั้ง');
      }
    } catch (err) {
      console.error('File upload error:', err);
      alert('เกิดข้อผิดพลาดในการอัปโหลดไฟล์');
    } finally {
      setIsUploadingFile(false);
    }
  };

  const handleSaveSong = async () => {
    if (!generatedTitleEn || generatedLyrics.length === 0) return;
    setIsSaving(true);
    try {
      const res = await fetch('/api/admin/bilingual-songs', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'saveSong',
          id: editingSongId,
          titleEn: generatedTitleEn,
          titleTh: generatedTitleTh,
          genre,
          targetWords: generatedWords,
          lyrics: generatedLyrics,
          audioUrl: generatedAudioUrl,
          isPublished: true,
        }),
      });

      if (res.ok) {
        alert(editingSongId ? 'แก้ไขเพลงเรียบร้อยแล้ว!' : 'บันทึกเพลงเรียบร้อยแล้ว!');
        resetForm();
        fetchSongs();
      }
    } catch (e) {
      console.error('Save song error:', e);
    } finally {
      setIsSaving(false);
    }
  };

  const handleEditSong = (song: Song) => {
    setEditingSongId(song.id);
    setGeneratedTitleEn(song.titleEn);
    setGeneratedTitleTh(song.titleTh);
    setGenre(song.genre);
    setGeneratedWords(song.targetWords || []);
    setGeneratedLyrics(song.lyrics || []);
    setGeneratedAudioUrl(song.audioUrl || '');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleDeleteSong = async (id: string) => {
    if (!confirm('คุณต้องการลบเพลงนี้ใช่หรือไม่?')) return;
    try {
      const res = await fetch('/api/admin/bilingual-songs', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'deleteSong', id }),
      });
      if (res.ok) {
        if (editingSongId === id) resetForm();
        fetchSongs();
      }
    } catch (e) {
      console.error('Delete song error:', e);
    }
  };

  const resetForm = () => {
    setEditingSongId(null);
    setGeneratedTitleEn('');
    setGeneratedTitleTh('');
    setGeneratedWords([]);
    setGeneratedLyrics([]);
    setGeneratedAudioUrl('');
  };

  const handleLyricChange = (index: number, field: keyof LyricLine, value: string) => {
    const updated = [...generatedLyrics];
    updated[index] = { ...updated[index], [field]: value };
    setGeneratedLyrics(updated);
  };

  const handleAddLyricLine = () => {
    setGeneratedLyrics([
      ...generatedLyrics,
      { lineEn: 'New English line', lineTh: 'ท่อนเนื้อเพลงภาษาไทยใหม่', chord: 'C' },
    ]);
  };

  const handleRemoveLyricLine = (index: number) => {
    const updated = generatedLyrics.filter((_, i) => i !== index);
    setGeneratedLyrics(updated);
  };

  const resolveMediaUrl = (rawUrl: string | null | undefined): string => {
    if (!rawUrl) return '';
    if (rawUrl.startsWith('data:') || rawUrl.startsWith('blob:')) return rawUrl;
    try {
      const uri = new URL(rawUrl);
      if (uri.port === '9000' || uri.pathname.startsWith('/avatars/')) {
        return `/api/media${uri.pathname}${uri.search}`;
      }
    } catch {
      if (rawUrl.startsWith('/avatars/')) {
        return `/api/media${rawUrl}`;
      }
    }
    return rawUrl;
  };

  const togglePlayAudio = (rawUrl: string) => {
    const url = resolveMediaUrl(rawUrl);
    if (!url) return;

    if (audioRef && isPlaying) {
      audioRef.pause();
      if (bgAudioRef) bgAudioRef.pause();
      setIsPlaying(false);
    } else {
      const newAudio = new Audio(url);
      const bgMusic = new Audio('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3');
      bgMusic.volume = 0.25;
      bgMusic.loop = true;

      newAudio.onended = () => {
        bgMusic.pause();
        setIsPlaying(false);
      };
      newAudio.onerror = (e) => {
        console.error('Audio playback load error:', e);
        bgMusic.pause();
        setIsPlaying(false);
      };

      setAudioRef(newAudio);
      setBgAudioRef(bgMusic);

      newAudio
        .play()
        .then(() => {
          bgMusic.play().catch(() => {});
          setIsPlaying(true);
        })
        .catch((err) => {
          console.warn('Audio play rejected:', err);
          setIsPlaying(false);
        });
    }
  };

  return (
    <div className="min-h-screen bg-gray--light1 p-6 lg:p-8">
      {/* Top Header */}
      <header className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8 border-b border-gray4 pb-6">
        <div>
          <div className="flex items-center gap-3">
            <div className="p-2.5 bg-purple--light5 text-purple rounded-xl">
              <Music className="w-8 h-8 animate-bounce" />
            </div>
            <div>
              <h1 className="text-3xl font-extrabold text-dark tracking-tight">
                Bilingual Songs & AI Guitar
              </h1>
              <p className="text-sm text-secondary--text mt-1">
                สร้างและจัดการเพลงสองภาษา (ไทย-อังกฤษ) สำหรับเด็ก และคอร์ดกีต้าร์สำหรับผู้ปกครองด้วย AI
              </p>
            </div>
          </div>
        </div>
        <div className="flex items-center gap-4">
          <button
            onClick={fetchSongs}
            className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-purple bg-purple--light5 hover:bg-purple--light6 transition rounded-lg border border-purple--light3"
          >
            <RefreshCw className="w-4 h-4" />
            Refresh Dashboard
          </button>
          <UserProfile />
        </div>
      </header>

      {/* Main Grid Section */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 mb-8">
        {/* Left Column: Form Controls */}
        <div className="lg:col-span-5 flex flex-col gap-6">
          <div className="bg-white rounded-2xl border border-gray4 shadow-sm overflow-hidden">
            <div className="p-5 border-b border-gray4 flex items-center justify-between bg-gray--light1">
              <div className="flex items-center gap-2.5">
                <Sparkles className="w-5 h-5 text-purple" />
                <h2 className="text-lg font-bold text-dark">
                  {editingSongId ? 'แก้ไขเพลงสองภาษา' : '1. กำหนดคำศัพท์ & แนวเพลง'}
                </h2>
              </div>
              {editingSongId && (
                <span className="text-xs bg-amber-100 text-amber-800 font-bold px-2.5 py-1 rounded-full border border-amber-300">
                  โหมดแก้ไข
                </span>
              )}
            </div>

            <div className="p-6 flex flex-col gap-5">
              <div>
                <label className="block text-sm font-semibold text-primary--text mb-2">
                  คำศัพท์ / ประโยคเป้าหมาย (แยกด้วยเครื่องหมายจุลภาค ,)
                </label>
                <textarea
                  rows={3}
                  value={phrasesInput}
                  onChange={(e) => setPhrasesInput(e.target.value)}
                  placeholder="เช่น: We can sing, We can play, Happy friends"
                  className="w-full p-3 rounded-xl border border-gray4 bg-white text-dark focus:ring-2 focus:ring-purple focus:outline-none text-sm"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-primary--text mb-2">
                  แนวเพลง (Genre & Style)
                </label>
                <select
                  value={genre}
                  onChange={(e) => setGenre(e.target.value)}
                  className="w-full p-3 rounded-xl border border-gray4 bg-white text-dark focus:ring-2 focus:ring-purple focus:outline-none text-sm"
                >
                  <option value="Upbeat Nursery Rhyme">Upbeat Nursery Rhyme (เพลงเด็กจังหวะสนุก)</option>
                  <option value="Acoustic Pop">Acoustic Pop (อะคูสติกสดใส)</option>
                  <option value="Cheerful Ukulele">Cheerful Ukulele (อูคูเลเล่ฟีลกู๊ด)</option>
                  <option value="Gentle Lullaby">Gentle Lullaby (เพลงกล่อมนอน)</option>
                </select>
              </div>

              <button
                onClick={handleGenerateLyrics}
                disabled={isGeneratingLyrics || !phrasesInput.trim()}
                className="w-full flex items-center justify-center gap-2 bg-purple hover:bg-purple--light6 disabled:opacity-50 text-white font-semibold py-3 px-4 rounded-xl shadow-sm transition"
              >
                {isGeneratingLyrics ? (
                  <>
                    <RefreshCw className="w-5 h-5 animate-spin" />
                    Qwen กำลังแต่งเนื้อเพลง & คอร์ด...
                  </>
                ) : (
                  <>
                    <Sparkles className="w-5 h-5 text-yellow-300" />
                    สร้างเนื้อเพลง & คอร์ดกีต้าร์ด้วย AI
                  </>
                )}
              </button>
            </div>
          </div>

          {/* Target Words Summary */}
          {generatedWords.length > 0 && (
            <div className="bg-white rounded-2xl border border-gray4 p-6 shadow-sm space-y-3">
              <h3 className="text-md font-bold text-dark flex items-center gap-2">
                <BookOpen className="w-4 h-4 text-purple" /> คำศัพท์เป้าหมาย (Target Vocabulary)
              </h3>
              <div className="flex flex-wrap gap-2">
                {generatedWords.map((w, idx) => (
                  <div
                    key={idx}
                    className="bg-purple--light5 border border-purple--light3 text-purple px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5"
                  >
                    <span>{w.word}</span>
                    <span className="text-secondary--text">({w.thaiMeaning})</span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Right Column: Generated / Editing Lyrics & Chords Preview */}
        <div className="lg:col-span-7">
          {generatedLyrics.length > 0 ? (
            <div className="bg-white rounded-2xl border border-gray4 shadow-sm overflow-hidden p-6 space-y-6">
              <div className="border-b border-gray4 pb-4 flex justify-between items-start gap-4">
                <div className="flex-1 space-y-2">
                  <div>
                    <label className="block text-[11px] font-bold text-secondary--text uppercase tracking-wider">
                      ชื่อเพลงภาษาอังกฤษ (English Title)
                    </label>
                    <input
                      type="text"
                      value={generatedTitleEn}
                      onChange={(e) => setGeneratedTitleEn(e.target.value)}
                      className="w-full text-xl font-extrabold text-purple bg-transparent border-b border-dashed border-purple/40 focus:outline-none"
                    />
                  </div>

                  <div>
                    <label className="block text-[11px] font-bold text-secondary--text uppercase tracking-wider">
                      ชื่อเพลงภาษาไทย (Thai Title)
                    </label>
                    <input
                      type="text"
                      value={generatedTitleTh}
                      onChange={(e) => setGeneratedTitleTh(e.target.value)}
                      className="w-full text-sm font-medium text-secondary--text bg-transparent border-b border-dashed border-gray4 focus:outline-none"
                    />
                  </div>
                </div>

                <span className="bg-purple--light5 text-purple text-xs font-semibold px-3 py-1 rounded-full border border-purple--light3 whitespace-nowrap">
                  {genre}
                </span>
              </div>

              {/* Lyrics & Chords Editor */}
              <div className="space-y-3">
                <div className="flex justify-between items-center">
                  <h3 className="text-sm font-bold text-dark flex items-center gap-2">
                    <Guitar className="w-4 h-4 text-amber-700" /> แก้ไขเนื้อเพลง & คอร์ดกีต้าร์
                  </h3>
                  <button
                    onClick={handleAddLyricLine}
                    className="flex items-center gap-1 text-xs font-bold text-purple hover:underline"
                  >
                    <Plus className="w-4 h-4" /> เพิ่มท่อนเนื้อเพลง
                  </button>
                </div>

                <div className="space-y-3 max-h-96 overflow-y-auto pr-2">
                  {generatedLyrics.map((line, idx) => (
                    <div
                      key={idx}
                      className="p-3.5 bg-gray--light1 rounded-xl border border-gray4 space-y-2 relative group"
                    >
                      <div className="flex items-center gap-3">
                        <span className="flex items-center gap-1 bg-amber-100 text-amber-900 px-2.5 py-1 rounded text-xs font-bold font-mono">
                          <Guitar className="w-3.5 h-3.5 text-amber-700" />
                          <input
                            type="text"
                            value={line.chord}
                            onChange={(e) => handleLyricChange(idx, 'chord', e.target.value)}
                            placeholder="คอร์ด"
                            className="bg-transparent font-bold focus:outline-none w-12 text-center"
                          />
                        </span>
                        <input
                          type="text"
                          value={line.lineEn}
                          onChange={(e) => handleLyricChange(idx, 'lineEn', e.target.value)}
                          placeholder="เนื้อเพลงภาษาอังกฤษ"
                          className="flex-1 font-bold text-dark bg-transparent border-b border-dashed border-gray4 focus:outline-none text-sm"
                        />
                        <button
                          onClick={() => handleRemoveLyricLine(idx)}
                          className="p-1 text-red-400 hover:text-red-600 transition"
                          title="ลบท่อนนี้"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                      <input
                        type="text"
                        value={line.lineTh}
                        onChange={(e) => handleLyricChange(idx, 'lineTh', e.target.value)}
                        placeholder="คำแปลภาษาไทย"
                        className="w-full text-xs text-secondary--text bg-transparent focus:outline-none pl-12"
                      />
                    </div>
                  ))}
                </div>
              </div>

              {/* Step 2: Audio Generation & MP3 Upload */}
              <div className="border-t border-gray4 pt-4 space-y-4">
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-3">
                  <h3 className="text-md font-bold text-dark flex items-center gap-2">
                    <Volume2 className="w-5 h-5 text-purple" /> 2. ไฟล์เสียงเพลงร้องจริง
                  </h3>

                  <div className="flex items-center gap-2">
                    {/* Upload MP3 File Button */}
                    <label className="flex items-center gap-2 bg-white hover:bg-gray--light1 text-purple border border-purple--light3 text-xs font-semibold px-3 py-2 rounded-xl cursor-pointer shadow-sm transition">
                      <Upload className="w-4 h-4 text-purple" />
                      {isUploadingFile ? 'กำลังอัปโหลด MP3...' : 'อัปโหลด MP3 จากคอมพิวเตอร์'}
                      <input
                        type="file"
                        accept="audio/*"
                        onChange={handleFileUpload}
                        disabled={isUploadingFile}
                        className="hidden"
                      />
                    </label>

                    <button
                      onClick={handleGenerateAudio}
                      disabled={isGeneratingAudio}
                      className="flex items-center gap-2 bg-purple hover:bg-purple--light6 text-white text-xs font-semibold px-4 py-2 rounded-xl shadow-sm transition disabled:opacity-50"
                    >
                      {isGeneratingAudio ? (
                        <>
                          <RefreshCw className="w-4 h-4 animate-spin" /> กำลังแต่งเพลง...
                        </>
                      ) : (
                        <>
                          <Music className="w-4 h-4" /> เจนเสียงอัตโนมัติด้วย AI
                        </>
                      )}
                    </button>
                  </div>
                </div>

                {/* Direct Audio URL Input */}
                <div className="space-y-1">
                  <label className="block text-xs font-semibold text-secondary--text">
                    หรือวางลิงก์ MP3 / Suno Audio URL โดยตรง:
                  </label>
                  <input
                    type="text"
                    value={generatedAudioUrl}
                    onChange={(e) => setGeneratedAudioUrl(e.target.value)}
                    placeholder="เช่น: https://suno.com/s/aZNMfxHpLnypFI06 หรือวางลิงก์ไฟล์ MP3"
                    className="w-full p-2.5 rounded-xl border border-gray4 bg-white text-dark focus:ring-2 focus:ring-purple focus:outline-none text-xs font-mono"
                  />
                </div>

                {generatedAudioUrl && (
                  <div className="flex items-center gap-4 bg-purple--light5 p-4 rounded-xl border border-purple--light3">
                    <button
                      onClick={() => togglePlayAudio(generatedAudioUrl)}
                      className="w-12 h-12 rounded-full bg-purple text-white flex items-center justify-center shadow-md hover:scale-105 transition"
                    >
                      {isPlaying ? <Pause className="w-6 h-6" /> : <Play className="w-6 h-6 ml-0.5" />}
                    </button>
                    <div className="flex-1 overflow-hidden">
                      <p className="text-xs font-bold text-purple">
                        พร้อมฟังเพลงร้องจริงที่เตรียมไว้
                      </p>
                      <p className="text-xs text-secondary--text truncate">
                        {generatedAudioUrl}
                      </p>
                    </div>
                  </div>
                )}
              </div>

              {/* Action Buttons */}
              <div className="flex justify-end gap-3 pt-4 border-t border-gray4">
                <button
                  onClick={resetForm}
                  className="px-4 py-2 rounded-xl text-sm font-medium text-secondary--text hover:bg-gray--light1"
                >
                  ยกเลิก
                </button>
                <button
                  onClick={handleSaveSong}
                  disabled={isSaving || !generatedTitleEn}
                  className="flex items-center gap-2 bg-purple hover:bg-purple--light6 text-white font-bold px-6 py-2.5 rounded-xl shadow-sm transition disabled:opacity-50"
                >
                  <Save className="w-4 h-4" />
                  {isSaving
                    ? 'กำลังบันทึก...'
                    : editingSongId
                    ? 'บันทึกการแก้ไขเพลง'
                    : 'บันทึกและเผยแพร่ลงแอป'}
                </button>
              </div>
            </div>
          ) : (
            <div className="bg-white rounded-2xl border-2 border-dashed border-gray4 p-12 text-center text-secondary--text flex flex-col items-center justify-center min-h-[380px] shadow-sm">
              <Music className="w-16 h-16 text-purple/40 mb-3 animate-pulse" />
              <p className="font-bold text-lg text-dark">ยังไม่มีเนื้อเพลง</p>
              <p className="text-sm max-w-md mt-1 text-secondary--text">
                กรอกคำศัพท์เป้าหมายด้านซ้าย แล้วกดปุ่ม <strong>"สร้างเนื้อเพลง & คอร์ดกีต้าร์"</strong>{' '}
                เพื่อเริ่มสร้างเพลงใหม่ หรือเลือกปุ่ม <strong>แก้ไข</strong> จากรายการเพลงด้านล่าง!
              </p>
            </div>
          )}
        </div>
      </div>

      {/* Published Songs Collection Table */}
      <div className="bg-white rounded-2xl border border-gray4 p-6 shadow-sm space-y-4">
        <div className="flex items-center justify-between border-b border-gray4 pb-4">
          <h2 className="text-xl font-bold text-dark flex items-center gap-2">
            <BookOpen className="w-5 h-5 text-purple" /> คลังเพลงสองภาษาทั้งหมด ({songs.length} เพลง)
          </h2>
        </div>

        {loading ? (
          <p className="text-sm text-secondary--text animate-pulse">กำลังโหลดคลังเพลง...</p>
        ) : songs.length === 0 ? (
          <p className="text-sm text-secondary--text py-4">ยังไม่มีเพลงสองภาษาในระบบ</p>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {songs.map((song) => (
              <div
                key={song.id}
                className={`p-4 rounded-xl border transition space-y-3 ${
                  editingSongId === song.id
                    ? 'border-purple bg-purple--light5 shadow-md ring-2 ring-purple/30'
                    : 'border-gray4 bg-gray--light1 hover:shadow-md'
                }`}
              >
                <div className="flex justify-between items-start">
                  <div>
                    <h3 className="font-extrabold text-dark text-md">
                      {song.titleEn}
                    </h3>
                    <p className="text-xs text-secondary--text">{song.titleTh}</p>
                  </div>
                  <span className="text-[10px] bg-purple--light5 text-purple font-semibold px-2 py-0.5 rounded border border-purple--light3">
                    {song.genre}
                  </span>
                </div>

                <div className="text-xs text-secondary--text">
                  <span className="font-semibold text-dark">คำศัพท์: </span>
                  {song.targetWords?.map((w) => w.word).join(', ') || '-'}
                </div>

                <div className="flex justify-between items-center pt-2 border-t border-gray4">
                  {song.audioUrl ? (
                    <button
                      onClick={() => togglePlayAudio(song.audioUrl!)}
                      className="flex items-center gap-1.5 text-xs text-purple font-bold hover:underline"
                    >
                      <Play className="w-3.5 h-3.5" /> ลองฟังเพลง
                    </button>
                  ) : (
                    <span className="text-[10px] text-secondary--text">ไม่มีไฟล์เสียง</span>
                  )}

                  <div className="flex items-center gap-1">
                    <button
                      onClick={() => handleEditSong(song)}
                      className="p-1.5 text-purple hover:bg-purple--light5 rounded-lg transition"
                      title="แก้ไขเนื้อร้อง & คอร์ด"
                    >
                      <Edit2 className="w-4 h-4" />
                    </button>

                    <button
                      onClick={() => handleDeleteSong(song.id)}
                      className="p-1.5 text-red-500 hover:bg-red-50 rounded-lg transition"
                      title="ลบเพลง"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
