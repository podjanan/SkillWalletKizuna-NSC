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
  Search,
  Upload,
  Download,
  Video,
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
  danceVideoUrl: string | null;
  coverUrl: string | null;
  isPublished: boolean;
  createdAt: string;
};

export default function BilingualSongsAdminPage() {
  const [songs, setSongs] = useState<Song[]>([]);
  const [loading, setLoading] = useState(true);

  // Form states
  const [phrasesInput, setPhrasesInput] = useState('We can sing, We can play, Happy friends');
  const [genre, setGenre] = useState(
    '30s short song, C Major, 125 BPM, aerobic dance pop, clear Thai English vocals, upbeat bouncy beat, synth brass'
  );

  // Generated / Editing results
  const [generatedTitleEn, setGeneratedTitleEn] = useState('');
  const [generatedTitleTh, setGeneratedTitleTh] = useState('');
  const [generatedWords, setGeneratedWords] = useState<TargetWord[]>([]);
  const [generatedLyrics, setGeneratedLyrics] = useState<LyricLine[]>([]);
  const [generatedAudioUrl, setGeneratedAudioUrl] = useState('');
  const [danceVideoUrl, setDanceVideoUrl] = useState('');
  const [sunoTracks, setSunoTracks] = useState<string[]>([]);

  // UI state
  const [isGeneratingLyrics, setIsGeneratingLyrics] = useState(false);
  const [isGeneratingAudio, setIsGeneratingAudio] = useState(false);
  const [isUploadingFile, setIsUploadingFile] = useState(false);
  const [isUploadingVideo, setIsUploadingVideo] = useState(false);
  const [videoUploadProgress, setVideoUploadProgress] = useState(0);
  const [isFetchingTaskTracks, setIsFetchingTaskTracks] = useState(false);
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
    if (isGeneratingAudio) return; // Guard against double clicks
    if (generatedLyrics.length === 0) {
      alert('กรุณาสร้างหรือใส่เนื้อเพลงก่อนเริ่มสร้างไฟล์เสียงด้วย Suno AI');
      return;
    }

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
        if (data.tracks && Array.isArray(data.tracks) && data.tracks.length > 0) {
          setSunoTracks(data.tracks);
          setGeneratedAudioUrl(data.tracks[0]);
          alert(`สร้างเพลงด้วย Suno AI สำเร็จเรียบร้อยแล้ว! (พบเพลงให้เลือก ${data.tracks.length} เวอร์ชัน)`);
        } else if (data.audioUrl) {
          setGeneratedAudioUrl(data.audioUrl);
          setSunoTracks([data.audioUrl]);
          alert('สร้างเพลงด้วย Suno AI สำเร็จเรียบร้อยแล้ว!');
        } else {
          alert('ไม่พบลิงก์เสียงจาก Suno AI โปรดตรวจสอบ Key ใน .env');
        }
      } else {
        const data = await res.json();
        alert(`เกิดข้อผิดพลาด: ${data.error || 'ไม่สามารถสร้างเพลงได้'}`);
      }
    } catch (e) {
      console.error('Audio generation error:', e);
      alert('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์');
    } finally {
      setIsGeneratingAudio(false);
    }
  };

  const handleFetchTaskTracks = async () => {
    const trimmed = generatedAudioUrl.trim();
    if (!trimmed) {
      alert('กรุณากรอก Task ID หรือ Suno URL ก่อนกดดึงเพลง');
      return;
    }
    setIsFetchingTaskTracks(true);
    try {
      const res = await fetch('/api/admin/bilingual-songs', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'fetchTaskTracks', taskId: trimmed }),
      });
      if (res.ok) {
        const data = await res.json();
        if (data.tracks && data.tracks.length > 0) {
          setSunoTracks(data.tracks);
          setGeneratedAudioUrl(data.tracks[0]);
          alert(`ดึงเพลงจาก Task ID สำเร็จ! พบเพลงให้เลือก ${data.tracks.length} เวอร์ชัน`);
        } else {
          alert('ไม่พบแทร็กเพลงใน Task ID นี้ หรือ Task ยังสร้างไม่เสร็จสิ้น');
        }
      } else {
        alert('เกิดข้อผิดพลาดในการดึงเพลงจาก Task ID');
      }
    } catch (e) {
      console.error('Fetch Task tracks error:', e);
      alert('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์');
    } finally {
      setIsFetchingTaskTracks(false);
    }
  };

  const handleDownloadAudio = async (url: string, defaultFilename: string) => {
    if (!url) return;
    try {
      const res = await fetch(url);
      const blob = await res.blob();
      const blobUrl = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = blobUrl;
      const cleanName = (defaultFilename || 'bilingual-song.mp3').replace(/[^a-zA-Z0-9_.-]/g, '_');
      a.download = cleanName.endsWith('.mp3') ? cleanName : `${cleanName}.mp3`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(blobUrl);
    } catch (err) {
      window.open(url, '_blank');
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

  const handleVideoUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (file.size > 200 * 1024 * 1024) {
      alert('ไฟล์วิดีโอต้องมีขนาดไม่เกิน 200 MB');
      e.target.value = '';
      return;
    }

    setIsUploadingVideo(true);
    setVideoUploadProgress(0);
    try {
      const res = await fetch('/api/admin/bilingual-songs', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'createVideoUpload',
          fileName: file.name,
          contentType: file.type,
          fileSize: file.size,
        }),
      });
      const data = await res.json();
      if (!res.ok || !data.uploadUrl || !data.publicUrl) {
        throw new Error(data.error || 'ไม่สามารถเตรียมการอัปโหลดวิดีโอได้');
      }

      await new Promise<void>((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        xhr.open('PUT', data.uploadUrl);
        xhr.setRequestHeader('Content-Type', file.type);
        xhr.timeout = 30 * 60 * 1000;
        xhr.upload.onprogress = (event) => {
          if (event.lengthComputable) {
            setVideoUploadProgress(Math.round((event.loaded / event.total) * 100));
          }
        };
        xhr.onload = () => {
          if (xhr.status >= 200 && xhr.status < 300) resolve();
          else reject(new Error(`MinIO upload failed (${xhr.status})`));
        };
        xhr.onerror = () => reject(new Error('การเชื่อมต่อ MinIO ถูกตัดระหว่างอัปโหลด'));
        xhr.ontimeout = () => reject(new Error('อัปโหลดนานเกิน 30 นาที กรุณาลองใหม่'));
        xhr.send(file);
      });

      setVideoUploadProgress(100);
      setDanceVideoUrl(data.publicUrl);
    } catch (err) {
      console.error('Video upload error:', err);
      alert(err instanceof Error ? err.message : 'เกิดข้อผิดพลาดในการอัปโหลดวิดีโอ');
    } finally {
      setIsUploadingVideo(false);
      e.target.value = '';
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
          danceVideoUrl,
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
    setDanceVideoUrl(song.danceVideoUrl || '');
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
    setDanceVideoUrl('');
    setSunoTracks([]);
  };

  const handleCreateManualLyrics = () => {
    setEditingSongId(null);
    if (!generatedTitleEn) setGeneratedTitleEn('New Song');
    if (!generatedTitleTh) setGeneratedTitleTh('เพลงใหม่');

    let initialWords = [...generatedWords];
    if (initialWords.length === 0 && phrasesInput.trim()) {
      initialWords = phrasesInput
        .split(',')
        .map((w) => w.trim())
        .filter(Boolean)
        .map((w) => ({ word: w, thaiMeaning: '' }));
      setGeneratedWords(initialWords);
    }

    if (generatedLyrics.length === 0) {
      setGeneratedLyrics([
        { lineEn: '[Intro]', lineTh: '', chord: 'C' },
        { lineEn: 'Sing together and play along', lineTh: '(ร้องเพลงไปด้วยกัน)', chord: 'C' },
      ]);
    }
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleAddTargetWord = () => {
    setGeneratedWords([...generatedWords, { word: '', thaiMeaning: '' }]);
  };

  const handleTargetWordChange = (index: number, field: keyof TargetWord, value: string) => {
    const updated = [...generatedWords];
    updated[index] = { ...updated[index], [field]: value };
    setGeneratedWords(updated);
  };

  const handleRemoveTargetWord = (index: number) => {
    const updated = generatedWords.filter((_, i) => i !== index);
    setGeneratedWords(updated);
  };

  const handleLyricChange = (index: number, field: keyof LyricLine, value: string) => {
    const updated = [...generatedLyrics];
    updated[index] = { ...updated[index], [field]: value };
    setGeneratedLyrics(updated);
  };

  const handleAddLyricLine = () => {
    if (generatedLyrics.length === 0) {
      handleCreateManualLyrics();
    } else {
      setGeneratedLyrics([
        ...generatedLyrics,
        { lineEn: '', lineTh: '', chord: '' },
      ]);
    }
  };

  const handleInsertSectionTag = (tag: string, atIndex?: number) => {
    const newLine: LyricLine = { lineEn: tag, lineTh: '', chord: '' };
    if (atIndex !== undefined) {
      const updated = [...generatedLyrics];
      updated.splice(atIndex, 0, newLine);
      setGeneratedLyrics(updated);
    } else {
      setGeneratedLyrics([...generatedLyrics, newLine]);
    }
  };

  const handleInsertLyricLineAbove = (index: number) => {
    const updated = [...generatedLyrics];
    updated.splice(index, 0, { lineEn: '', lineTh: '', chord: '' });
    setGeneratedLyrics(updated);
  };

  const handleMoveLyricLine = (fromIndex: number, toIndex: number) => {
    if (toIndex < 0 || toIndex >= generatedLyrics.length) return;
    const updated = [...generatedLyrics];
    const [moved] = updated.splice(fromIndex, 1);
    updated.splice(toIndex, 0, moved);
    setGeneratedLyrics(updated);
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

    if (audioRef) {
      if (isPlaying) {
        audioRef.pause();
        setIsPlaying(false);
        return;
      }
    }

    const newAudio = new Audio(url);
    newAudio.onended = () => {
      setIsPlaying(false);
    };
    newAudio.onerror = (e) => {
      console.error('Audio playback load error:', e);
      setIsPlaying(false);
    };

    setAudioRef(newAudio);

    newAudio
      .play()
      .then(() => {
        setIsPlaying(true);
      })
      .catch((err) => {
        console.warn('Audio play rejected:', err);
        setIsPlaying(false);
      });
  };

  const getShortGenreDisplay = (g: string) => {
    if (!g) return 'Upbeat Nursery Rhyme';
    if (g.length <= 25) return g;
    if (g.toLowerCase().includes('aerobic')) return '30s Aerobic Dance Pop';
    return g.substring(0, 22) + '...';
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
                Sing Together
              </h1>
              <p className="text-sm text-secondary--text mt-1">
                สร้างและจัดการเพลงสองภาษา (ไทย-อังกฤษ) สำหรับเด็ก และคอร์ดกีต้าร์สำหรับผู้ปกครองด้วย AI
              </p>
            </div>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={fetchSongs}
            className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-purple bg-purple--light5 hover:bg-purple--light6 transition rounded-xl border border-purple--light3"
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
                <label className="block text-sm font-semibold text-primary--text mb-1">
                  แนวเพลง & สไตล์ดนตรี (Genre & Style Prompts for Suno)
                </label>
                <p className="text-xs text-secondary--text mb-2">
                  เลือกจากสไตล์สำเร็จรูป หรือพิมพ์กำหนด Prompt สเปคดนตรีเชิงลึกเองได้เลย
                </p>
                <div className="space-y-2">
                  <select
                    value={
                      [
                        'Upbeat Nursery Rhyme',
                        '30s short song, C Major, 125 BPM, aerobic dance pop, clear Thai English vocals, upbeat bouncy beat, synth brass',
                        'Acoustic Pop',
                        'Cheerful Ukulele',
                        'Gentle Lullaby',
                      ].includes(genre)
                        ? genre
                        : 'custom'
                    }
                    onChange={(e) => {
                      if (e.target.value !== 'custom') {
                        setGenre(e.target.value);
                      }
                    }}
                    className="w-full p-2.5 rounded-xl border border-gray4 bg-white text-dark focus:ring-2 focus:ring-purple focus:outline-none text-xs font-semibold"
                  >
                    <option value="30s short song, C Major, 125 BPM, aerobic dance pop, clear Thai English vocals, upbeat bouncy beat, synth brass">
                      ⭐ 30s Aerobic Dance Pop (125 BPM, Clear Vocal, Synth Brass) [แนะนำ]
                    </option>
                    <option value="Upbeat Nursery Rhyme">Upbeat Nursery Rhyme (เพลงเด็กจังหวะสนุก)</option>
                    <option value="Acoustic Pop">Acoustic Pop (อะคูสติกสดใส)</option>
                    <option value="Cheerful Ukulele">Cheerful Ukulele (อูคูเลเล่ฟีลกู๊ด)</option>
                    <option value="Gentle Lullaby">Gentle Lullaby (เพลงกล่อมนอน)</option>
                    <option value="custom">✏️ กำหนดสเปค Prompt เอง (Custom Style)</option>
                  </select>

                  <textarea
                    rows={3}
                    value={genre}
                    onChange={(e) => setGenre(e.target.value)}
                    placeholder="พิมพ์ Style Prompt เช่น: 30 second short song, 125 BPM, aerobic dance pop..."
                    className="w-full p-3 rounded-xl border border-gray4 bg-white text-dark focus:ring-2 focus:ring-purple focus:outline-none text-xs font-mono"
                  />
                </div>
              </div>

              <div className="flex flex-col gap-2.5">
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

                <button
                  onClick={handleCreateManualLyrics}
                  className="w-full flex items-center justify-center gap-2 bg-white hover:bg-purple--light5 text-purple border-2 border-purple/30 hover:border-purple font-bold py-2.5 px-4 rounded-xl shadow-sm transition text-sm"
                >
                  <Plus className="w-4 h-4 text-purple" />
                  สร้างเนื้อเพลงด้วยตนเอง (Manual)
                </button>
              </div>
            </div>
          </div>

          {/* Target Words Section */}
          <div className="bg-white rounded-2xl border border-gray4 p-5 shadow-sm space-y-3">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-bold text-dark flex items-center gap-2">
                <BookOpen className="w-4 h-4 text-purple" /> คำศัพท์เป้าหมาย (Target Vocabulary)
              </h3>
              <button
                onClick={handleAddTargetWord}
                className="flex items-center gap-1 px-2 py-1 text-xs font-bold text-purple bg-purple--light5 hover:bg-purple--light4 border border-purple/20 rounded-lg transition"
              >
                <Plus className="w-3.5 h-3.5" /> เพิ่มคำศัพท์
              </button>
            </div>

            {generatedWords.length === 0 ? (
              <p className="text-xs text-secondary--text italic">
                ยังไม่มีคำศัพท์เป้าหมาย กด "+ เพิ่มคำศัพท์" เพื่อกำหนดเอง
              </p>
            ) : (
              <div className="space-y-2">
                {generatedWords.map((w, idx) => (
                  <div
                    key={idx}
                    className="flex items-center gap-2 bg-purple--light5 border border-purple--light3 p-2 rounded-xl"
                  >
                    <input
                      type="text"
                      value={w.word}
                      onChange={(e) => handleTargetWordChange(idx, 'word', e.target.value)}
                      placeholder="คำศัพท์ภาษาอังกฤษ (e.g. Sing)"
                      className="w-1/2 text-xs font-bold text-purple bg-white border border-purple/20 px-2 py-1 rounded focus:outline-none"
                    />
                    <input
                      type="text"
                      value={w.thaiMeaning}
                      onChange={(e) => handleTargetWordChange(idx, 'thaiMeaning', e.target.value)}
                      placeholder="ความหมายภาษาไทย (e.g. ร้องเพลง)"
                      className="w-1/2 text-xs text-secondary--text bg-white border border-gray4 px-2 py-1 rounded focus:outline-none"
                    />
                    <button
                      onClick={() => handleRemoveTargetWord(idx)}
                      className="text-red-400 hover:text-red-600 p-1 transition"
                      title="ลบคำศัพท์นี้"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
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

                <span
                  className="bg-purple--light5 text-purple text-xs font-semibold px-3 py-1 rounded-full border border-purple--light3 shrink-0"
                  title={genre}
                >
                  {getShortGenreDisplay(genre)}
                </span>
              </div>

              {/* Lyrics & Structure Editor */}
              <div className="space-y-3">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b border-gray4 pb-3">
                  <h3 className="text-sm font-bold text-dark flex items-center gap-2">
                    <Guitar className="w-4 h-4 text-purple" /> แก้ไขเนื้อเพลง & แทรกท่อนเพลง (Structure)
                  </h3>
                  <div className="flex flex-wrap items-center gap-1.5">
                    <button
                      onClick={() => handleInsertSectionTag('[Key: C Major]')}
                      className="px-2 py-1 bg-amber-100 hover:bg-amber-200 text-amber-900 text-xs font-bold rounded-lg transition"
                      title="แทรก [Key: C Major]"
                    >
                      + [Key]
                    </button>
                    <button
                      onClick={() => handleInsertSectionTag('[Intro]')}
                      className="px-2 py-1 bg-purple--light5 hover:bg-purple--light4 text-purple text-xs font-bold rounded-lg border border-purple/20 transition"
                    >
                      + [Intro]
                    </button>
                    <button
                      onClick={() => handleInsertSectionTag('[Verse]')}
                      className="px-2 py-1 bg-purple--light5 hover:bg-purple--light4 text-purple text-xs font-bold rounded-lg border border-purple/20 transition"
                    >
                      + [Verse]
                    </button>
                    <button
                      onClick={() => handleInsertSectionTag('[Chorus]')}
                      className="px-2 py-1 bg-purple--light5 hover:bg-purple--light4 text-purple text-xs font-bold rounded-lg border border-purple/20 transition"
                    >
                      + [Chorus]
                    </button>
                    <button
                      onClick={() => handleInsertSectionTag('[Outro]')}
                      className="px-2 py-1 bg-purple--light5 hover:bg-purple--light4 text-purple text-xs font-bold rounded-lg border border-purple/20 transition"
                    >
                      + [Outro]
                    </button>
                    <button
                      onClick={handleAddLyricLine}
                      className="flex items-center gap-1 px-2.5 py-1 bg-purple text-white text-xs font-bold rounded-lg shadow-sm hover:bg-purple--light6 transition"
                    >
                      <Plus className="w-3.5 h-3.5" /> เพิ่มท่อน
                    </button>
                  </div>
                </div>

                <div className="space-y-3 max-h-[420px] overflow-y-auto pr-2">
                  {generatedLyrics.map((line, idx) => {
                    const isSectionHeader = line.lineEn.trim().startsWith('[');
                    return (
                      <div
                        key={idx}
                        className={`p-3.5 rounded-xl border space-y-2 relative group transition ${
                          isSectionHeader
                            ? 'bg-purple--light5 border-purple/30 font-bold'
                            : 'bg-gray--light1 border-gray4 hover:border-purple/20'
                        }`}
                      >
                        <div className="flex items-center gap-2">
                          <span className="flex items-center gap-1 bg-amber-100 text-amber-900 px-2 py-1 rounded text-xs font-bold font-mono">
                            <Guitar className="w-3.5 h-3.5 text-amber-700" />
                            <input
                              type="text"
                              value={line.chord}
                              onChange={(e) => handleLyricChange(idx, 'chord', e.target.value)}
                              placeholder="Key/คอร์ด"
                              className="bg-transparent font-bold focus:outline-none w-16 text-center"
                            />
                          </span>

                          <input
                            type="text"
                            value={line.lineEn}
                            onChange={(e) => handleLyricChange(idx, 'lineEn', e.target.value)}
                            placeholder="เนื้อเพลงภาษาอังกฤษ / [Section เช่น Intro]"
                            className={`flex-1 font-bold bg-transparent border-b border-dashed border-gray4 focus:outline-none text-sm ${
                              isSectionHeader ? 'text-purple text-base' : 'text-dark'
                            }`}
                          />

                          {/* Line Action Tools: Insert Above, Move Up, Move Down, Delete */}
                          <div className="flex items-center gap-1 opacity-80 group-hover:opacity-100 transition">
                            <button
                              onClick={() => handleInsertLyricLineAbove(idx)}
                              className="px-2 py-0.5 bg-white border border-gray4 hover:bg-purple--light5 text-[11px] font-semibold text-purple rounded"
                              title="แทรกท่อนด้านบนบรรทัดนี้"
                            >
                              + แทรกบน
                            </button>
                            <button
                              onClick={() => handleMoveLyricLine(idx, idx - 1)}
                              disabled={idx === 0}
                              className="p-1 text-gray-500 hover:text-purple disabled:opacity-30"
                              title="ย้ายขึ้น"
                            >
                              ↑
                            </button>
                            <button
                              onClick={() => handleMoveLyricLine(idx, idx + 1)}
                              disabled={idx === generatedLyrics.length - 1}
                              className="p-1 text-gray-500 hover:text-purple disabled:opacity-30"
                              title="ย้ายลง"
                            >
                              ↓
                            </button>
                            <button
                              onClick={() => handleRemoveLyricLine(idx)}
                              className="p-1 text-red-400 hover:text-red-600 transition"
                              title="ลบท่อนนี้"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </div>
                        </div>

                        {(!isSectionHeader || line.lineTh) && (
                          <input
                            type="text"
                            value={line.lineTh}
                            onChange={(e) => handleLyricChange(idx, 'lineTh', e.target.value)}
                            placeholder="ท่อนร้องในวงเล็บ เช่น (แปล - ว่า - ร้อง - เพลง!)"
                            className="w-full text-xs text-secondary--text bg-transparent focus:outline-none pl-12"
                          />
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Step 2: Audio File Generation & Upload */}
              <div className="border-t border-gray4 pt-4 space-y-4">
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-3">
                  <h3 className="text-md font-bold text-dark flex items-center gap-2">
                    <Volume2 className="w-5 h-5 text-purple" /> 2. สร้างไฟล์เสียงเพลงด้วย Suno AI หรืออัปโหลด MP3
                  </h3>

                  <div className="flex flex-wrap items-center gap-2">
                    {/* Generate Suno Audio Button (Strict Single Click Guard) */}
                    <button
                      onClick={handleGenerateAudio}
                      disabled={isGeneratingAudio || generatedLyrics.length === 0}
                      className="flex items-center gap-2 bg-gradient-to-r from-purple to-indigo-600 hover:from-purple--light6 hover:to-indigo-700 disabled:opacity-50 text-white text-xs font-bold px-4 py-2.5 rounded-xl shadow-sm transition"
                    >
                      {isGeneratingAudio ? (
                        <>
                          <RefreshCw className="w-4 h-4 animate-spin text-yellow-300" />
                          <span>กำลังส่งยิง Suno AI (ส่งคำสั่งรอบเดียว รอสักครู่)...</span>
                        </>
                      ) : (
                        <>
                          <Sparkles className="w-4 h-4 text-yellow-300" />
                          <span>สร้างไฟล์เสียงเพลงด้วย Suno AI</span>
                        </>
                      )}
                    </button>

                    {/* Upload MP3 File Button */}
                    <label className="flex items-center gap-2 bg-gray-700 hover:bg-gray-800 text-white text-xs font-semibold px-4 py-2.5 rounded-xl cursor-pointer shadow-sm transition">
                      <Upload className="w-4 h-4 text-white" />
                      {isUploadingFile ? 'กำลังอัปโหลด MP3...' : 'เลือกไฟล์ MP3 เอง'}
                      <input
                        type="file"
                        accept="audio/*"
                        onChange={handleFileUpload}
                        disabled={isUploadingFile}
                        className="hidden"
                      />
                    </label>
                  </div>
                </div>

                {/* Direct Audio URL Input */}
                <div className="space-y-1">
                  <label className="block text-xs font-semibold text-secondary--text">
                    หรือวางลิงก์ MP3 / Suno Task ID โดยตรง:
                  </label>
                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={generatedAudioUrl}
                      onChange={(e) => setGeneratedAudioUrl(e.target.value)}
                      placeholder="วาง Task ID (เช่น bf2df74b-0128-...) หรือวางลิงก์ไฟล์ MP3"
                      className="flex-1 p-2.5 rounded-xl border border-gray4 bg-white text-dark focus:ring-2 focus:ring-purple focus:outline-none text-xs font-mono"
                    />
                    {generatedAudioUrl.trim().length >= 30 && !generatedAudioUrl.trim().startsWith('http') && (
                      <button
                        type="button"
                        onClick={handleFetchTaskTracks}
                        disabled={isFetchingTaskTracks}
                        className="px-3.5 py-2 bg-purple-600 hover:bg-purple-700 text-white font-bold text-xs rounded-xl shadow-sm transition flex items-center gap-1.5 whitespace-nowrap"
                      >
                        {isFetchingTaskTracks ? (
                          <>
                            <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                            <span>กำลังดึงเพลง...</span>
                          </>
                        ) : (
                          <>
                            <Search className="w-3.5 h-3.5" />
                            <span>ดึงทั้ง 2 เพลงจาก Task ID</span>
                          </>
                        )}
                      </button>
                    )}
                  </div>
                </div>

                {/* Suno Audio Track Variations Selector (Preview both tracks & select 1) */}
                {sunoTracks.length > 1 && (
                  <div className="mt-3 p-4 bg-gradient-to-r from-purple-50 to-indigo-50 border border-purple-200 rounded-2xl space-y-3">
                    <div className="flex items-center justify-between">
                      <h4 className="text-xs font-bold text-purple-900 flex items-center gap-1.5">
                        <Sparkles className="w-4 h-4 text-purple-600" />
                        Suno AI ได้สร้างเพลงออกมา 2 เวอร์ชัน (ลองกดฟังและคลิกเลือกเวอร์ชันที่ชอบได้เลย):
                      </h4>
                      <span className="text-[10px] bg-purple-200 text-purple-800 font-bold px-2 py-0.5 rounded-full">
                        2 Variations
                      </span>
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                      {sunoTracks.map((trackUrl, idx) => {
                        const isSelected = generatedAudioUrl === trackUrl;
                        return (
                          <div
                            key={idx}
                            className={`p-3 rounded-xl border transition-all ${
                              isSelected
                                ? 'bg-white border-purple-500 shadow-md ring-2 ring-purple-300'
                                : 'bg-white/80 border-purple-200 hover:border-purple-300'
                            }`}
                          >
                            <div className="flex items-center justify-between mb-2">
                              <span className="font-bold text-xs text-purple-900">
                                🎵 เวอร์ชันที่ {idx + 1}
                              </span>
                              {isSelected && (
                                <span className="text-[10px] bg-purple-600 text-white font-bold px-2 py-0.5 rounded-full">
                                  กำลังเลือกใช้งาน
                                </span>
                              )}
                            </div>
                            <audio controls src={trackUrl} className="w-full h-8 mb-2.5" />
                            <div className="flex gap-2">
                              <button
                                type="button"
                                onClick={() => setGeneratedAudioUrl(trackUrl)}
                                className={`flex-1 py-1.5 px-3 rounded-lg text-xs font-bold transition-all ${
                                  isSelected
                                    ? 'bg-purple-600 text-white shadow-sm'
                                    : 'bg-purple-100 text-purple-800 hover:bg-purple-200'
                                }`}
                              >
                                {isSelected ? '✓ เลือกเวอร์ชันนี้แล้ว' : `เลือกเวอร์ชันที่ ${idx + 1}`}
                              </button>
                              <button
                                type="button"
                                onClick={() => handleDownloadAudio(trackUrl, `${generatedTitleEn || 'song'}_version${idx + 1}.mp3`)}
                                className="p-1.5 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-lg transition flex items-center justify-center shrink-0"
                                title={`ดาวน์โหลด MP3 เวอร์ชันที่ ${idx + 1}`}
                              >
                                <Download className="w-4 h-4" />
                              </button>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                )}

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
                    <button
                      type="button"
                      onClick={() => handleDownloadAudio(generatedAudioUrl, `${generatedTitleEn || 'bilingual-song'}.mp3`)}
                      className="flex items-center gap-1.5 px-3 py-1.5 bg-white border border-purple-300 hover:bg-purple-50 text-purple-700 font-bold text-xs rounded-xl shadow-sm transition shrink-0"
                      title="ดาวน์โหลดไฟล์ MP3 ลงเครื่อง"
                    >
                      <Download className="w-3.5 h-3.5" />
                      <span>โหลด MP3</span>
                    </button>
                  </div>
                )}
              </div>

              {/* Step 3: Dance demonstration video */}
              <div className="border-t border-gray4 pt-4 space-y-4">
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-3">
                  <div>
                    <h3 className="text-md font-bold text-dark flex items-center gap-2">
                      <Video className="w-5 h-5 text-purple" /> 3. วิดีโอเต้นตัวอย่าง
                    </h3>
                    <p className="text-xs text-secondary--text mt-1">
                      เพิ่มคลิปสาธิตท่าเต้นเพื่อให้เด็กเปิดดูก่อนหรือระหว่างทำกิจกรรม
                    </p>
                  </div>
                  <label className="flex items-center gap-2 bg-purple hover:bg-purple--light6 text-white text-xs font-semibold px-4 py-2.5 rounded-xl cursor-pointer shadow-sm transition">
                    <Upload className="w-4 h-4" />
                    {isUploadingVideo ? `กำลังอัปโหลด ${videoUploadProgress}%` : danceVideoUrl ? 'เปลี่ยนวิดีโอ' : 'เลือกไฟล์วิดีโอ'}
                    <input
                      type="file"
                      accept="video/*"
                      onChange={handleVideoUpload}
                      disabled={isUploadingVideo}
                      className="hidden"
                    />
                  </label>
                </div>

                {isUploadingVideo && (
                  <div className="space-y-1.5">
                    <div className="h-2 overflow-hidden rounded-full bg-purple--light4">
                      <div
                        className="h-full rounded-full bg-purple transition-all duration-200"
                        style={{ width: `${videoUploadProgress}%` }}
                      />
                    </div>
                    <p className="text-right text-xs font-semibold text-purple">{videoUploadProgress}%</p>
                  </div>
                )}

                <div className="space-y-1">
                  <label className="block text-xs font-semibold text-secondary--text">
                    หรือวางลิงก์วิดีโอโดยตรง:
                  </label>
                  <input
                    type="url"
                    value={danceVideoUrl}
                    onChange={(e) => setDanceVideoUrl(e.target.value)}
                    placeholder="https://example.com/dance-example.mp4"
                    className="w-full p-2.5 rounded-xl border border-gray4 bg-white text-dark focus:ring-2 focus:ring-purple focus:outline-none text-xs font-mono"
                  />
                </div>

                {danceVideoUrl && (
                  <div className="rounded-2xl border border-purple--light3 bg-purple--light5 p-3 space-y-2">
                    <video
                      src={danceVideoUrl}
                      controls
                      preload="metadata"
                      className="w-full max-h-80 rounded-xl bg-black"
                    />
                    <div className="flex items-center justify-between gap-3">
                      <p className="text-xs text-secondary--text truncate">{danceVideoUrl}</p>
                      <button
                        type="button"
                        onClick={() => setDanceVideoUrl('')}
                        className="shrink-0 px-3 py-1.5 text-xs font-bold text-red-600 hover:bg-red-50 rounded-lg transition"
                      >
                        ลบวิดีโอ
                      </button>
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
                กรอกคำศัพท์เป้าหมายด้านซ้าย แล้วกดปุ่ม <strong>"สร้างเนื้อเพลง & คอร์ดกีต้าร์ด้วย AI"</strong>{' '}
                หรือกดปุ่ม <strong>"สร้างเนื้อเพลงด้วยตนเอง (Manual)"</strong> จากเมนูด้านซ้ายเพื่อเริ่มสร้างเพลงใหม่!
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
                  <span
                    className="text-[10px] bg-purple--light5 text-purple font-semibold px-2 py-0.5 rounded border border-purple--light3 shrink-0"
                    title={song.genre}
                  >
                    {getShortGenreDisplay(song.genre)}
                  </span>
                </div>

                <div className="text-xs text-secondary--text">
                  <span className="font-semibold text-dark">คำศัพท์: </span>
                  {song.targetWords?.map((w) => w.word).join(', ') || '-'}
                </div>

                <div className="flex justify-between items-center pt-2 border-t border-gray4">
                  <div className="flex flex-wrap items-center gap-3">
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
                    {song.danceVideoUrl && (
                      <a
                        href={song.danceVideoUrl}
                        target="_blank"
                        rel="noreferrer"
                        className="flex items-center gap-1.5 text-xs text-indigo-600 font-bold hover:underline"
                      >
                        <Video className="w-3.5 h-3.5" /> ดูท่าเต้น
                      </a>
                    )}
                  </div>

                  <div className="flex items-center gap-1">
                    {song.audioUrl && (
                      <button
                        onClick={() => handleDownloadAudio(song.audioUrl!, `${song.titleEn}.mp3`)}
                        className="p-1.5 text-secondary--text hover:text-purple hover:bg-purple--light5 rounded-lg transition"
                        title="ดาวน์โหลดไฟล์เสียง MP3"
                      >
                        <Download className="w-4 h-4" />
                      </button>
                    )}

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
