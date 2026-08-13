import { prisma } from '@/lib/prisma';
import { callOllama } from '@/lib/ai-word-game';
import { uploadToMinio } from '@/lib/minio';

export type LyricLine = {
  lineEn: string;
  lineTh: string;
  chord: string; // e.g. "C", "G", "Am", "F", or "C - G"
};

export type TargetWord = {
  word: string;
  thaiMeaning: string;
  phonetic?: string;
};

export type BilingualSong = {
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
  updatedAt: string;
};

function extractJson(text: string): Record<string, unknown> | null {
  try {
    return JSON.parse(text);
  } catch {
    const match = text.match(/\{[\s\S]*\}/);
    if (!match) return null;
    try {
      return JSON.parse(match[0]);
    } catch {
      return null;
    }
  }
}

export async function ensureBilingualSongTable() {
  await prisma.$executeRaw`
    CREATE TABLE IF NOT EXISTS bilingual_song (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      title_en TEXT NOT NULL,
      title_th TEXT NOT NULL,
      genre TEXT NOT NULL DEFAULT 'Upbeat Nursery Rhyme',
      target_words JSONB NOT NULL DEFAULT '[]'::jsonb,
      lyrics JSONB NOT NULL DEFAULT '[]'::jsonb,
      audio_url TEXT,
      cover_url TEXT,
      is_published BOOLEAN NOT NULL DEFAULT true,
      created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  `;
}

export async function generateBilingualLyricsWithQwen(
  targetPhrases: string[],
  genre = 'Upbeat Nursery Rhyme'
): Promise<{
  titleEn: string;
  titleTh: string;
  targetWords: TargetWord[];
  lyrics: LyricLine[];
}> {
  const phrasesStr = targetPhrases.join(', ');
  const isShort = genre.toLowerCase().includes('30') || genre.toLowerCase().includes('short');
  const lengthRule = isShort
    ? ' Keep lyrics extra short and punchy (max 4-6 total sung lines) designed for a 30-second song.'
    : '';
  const prompt = `You are a creative children's songwriter and language teacher.
Create a short, catchy bilingual song for kids ages 4-9 based on these target vocabulary words: "${phrasesStr}".${lengthRule}

CRITICAL LYRICS FORMATTING RULES:
1. Do NOT generate individual chords per line (leave chord as "").
2. The FIRST item of lyrics MUST specify the key header: "[Key: C Major]" (or G Major, F Major).
3. Organize the lyrics into clear section headers: "[Intro]", "[Verse]", "[Chorus]", "[Outro]".
4. Under each section, each line consists of an English chant/lyric and matching Thai sung lyrics in parentheses (separating syllables with hyphens).
5. Do NOT include formal prose translations or sentence translations. The Thai part IS the sung rhythmic lyrics!

EXACT EXPECTED FORMAT:
[Key: C Major]
[Intro]
(1, 2, 3, Go!)

[Verse]
Sing! Sing! (แปล - ว่า - ร้อง - เพลง!)
Play! Play! (แปล - ว่า - เล่น!)
Happy! Happy! (มี - ความ - สุข!)

[Chorus]
We can sing! (ร้อง - เพลง!)
We can play! (เล่น - สนุก!)
Sing, Play, Happy now! (มี - ความ - สุข - จัง!)

[Outro]
Sing! Play! Happy! (Jump! Jump! Go!)

Return ONLY valid JSON:
{
  "titleEn": "Sing, Play and Happy Song",
  "titleTh": "เพลง ร้อง เล่น และมีความสุข",
  "targetWords": [
    { "word": "sing", "thaiMeaning": "ร้องเพลง", "phonetic": "sing" },
    { "word": "play", "thaiMeaning": "เล่น", "phonetic": "play" },
    { "word": "happy", "thaiMeaning": "มีความสุข", "phonetic": "happy" }
  ],
  "lyrics": [
    { "lineEn": "[Key: C Major]", "lineTh": "", "chord": "" },
    { "lineEn": "[Intro]", "lineTh": "", "chord": "" },
    { "lineEn": "(1, 2, 3, Go!)", "lineTh": "", "chord": "" },
    { "lineEn": "[Verse]", "lineTh": "", "chord": "" },
    { "lineEn": "Sing! Sing!", "lineTh": "(แปล - ว่า - ร้อง - เพลง!)", "chord": "" },
    { "lineEn": "Play! Play!", "lineTh": "(แปล - ว่า - เล่น!)", "chord": "" },
    { "lineEn": "Happy! Happy!", "lineTh": "(มี - ความ - สุข!)", "chord": "" },
    { "lineEn": "[Chorus]", "lineTh": "", "chord": "" },
    { "lineEn": "We can sing!", "lineTh": "(ร้อง - เพลง!)", "chord": "" },
    { "lineEn": "We can play!", "lineTh": "(เล่น - สนุก!)", "chord": "" },
    { "lineEn": "Sing, Play, Happy now!", "lineTh": "(มี - ความ - สุข - จัง!)", "chord": "" },
    { "lineEn": "[Outro]", "lineTh": "", "chord": "" },
    { "lineEn": "Sing! Play! Happy!", "lineTh": "(Jump! Jump! Go!)", "chord": "" }
  ]
}`;

  // Attempt Ollama call up to 3 times with retry to handle ECONNRESET
  for (let attempt = 1; attempt <= 3; attempt++) {
    try {
      console.log(`[Qwen Lyric Engine] Attempt ${attempt}/3 sending prompt for phrases: [${phrasesStr}]...`);
      const responseText = await callOllama(prompt, true, 0.3);
      const parsed = extractJson(responseText);

      if (parsed && parsed.titleEn && Array.isArray(parsed.lyrics) && parsed.lyrics.length > 0) {
        console.log(`[Qwen Lyric Engine] ✅ Generated lyrics successfully! Title: ${parsed.titleEn}`);
        return {
          titleEn: String(parsed.titleEn || 'Kids Happy Song'),
          titleTh: String(parsed.titleTh || 'เพลงเด็กสุดสนุก'),
          targetWords: Array.isArray(parsed.targetWords)
            ? (parsed.targetWords as TargetWord[]).map((w) => ({
                word: String(w.word || ''),
                thaiMeaning: String(w.thaiMeaning || ''),
                phonetic: String(w.phonetic || w.word || ''),
              }))
            : targetPhrases.map((p) => ({ word: p, thaiMeaning: p, phonetic: p })),
          lyrics: (parsed.lyrics as LyricLine[]).map((l) => ({
            lineEn: String(l.lineEn || ''),
            lineTh: String(l.lineTh || ''),
            chord: String(l.chord || ''),
          })),
        };
      }
    } catch (error) {
      console.warn(`[Qwen Lyric Engine] Attempt ${attempt} failed:`, error);
      if (attempt < 3) {
        await new Promise((res) => setTimeout(res, 1000 * attempt));
      }
    }
  }

  // Dynamic phrase-based fallback template (uses ALL target phrases entered by admin)
  console.log('[Lyric Engine] Building structured template...');
  const wordsList = targetPhrases.map((w) => w.trim()).filter(Boolean);
  
  const thaiMeaningMap: Record<string, string> = {
    sing: '(แปล - ว่า - ร้อง - เพลง!)',
    play: '(แปล - ว่า - เล่น!)',
    happy: '(มี - ความ - สุข!)',
    sleep: '(แปล - ว่า - นอน - หลับ!)',
    run: '(แปล - ว่า - วิ่ง!)',
    eat: '(แปล - ว่า - กิน!)',
    dance: '(แปล - ว่า - เต้น - ระบำ!)',
    jump: '(กระ - โดด!)',
    cat: '(แปล - ว่า - แมว!)',
    dog: '(แปล - ว่า - สุนัข!)',
  };

  const dynamicLyrics: LyricLine[] = [
    { lineEn: '[Key: C Major]', lineTh: '', chord: '' },
    { lineEn: '[Intro]', lineTh: '', chord: '' },
    { lineEn: '(1, 2, 3, Go!)', lineTh: '', chord: '' },
    { lineEn: '[Verse]', lineTh: '', chord: '' },
  ];

  for (const w of wordsList) {
    const lower = w.toLowerCase();
    const formattedEn = `${w.substring(0, 1).toUpperCase()}${w.substring(1)}! ${w.substring(0, 1).toUpperCase()}${w.substring(1)}!`;
    const thMeaning = thaiMeaningMap[lower] || `(แปล - ว่า - ${w}!)`;
    dynamicLyrics.push({
      lineEn: formattedEn,
      lineTh: thMeaning,
      chord: '',
    });
  }

  dynamicLyrics.push({ lineEn: '[Chorus]', lineTh: '', chord: '' });
  if (wordsList.length >= 2) {
    dynamicLyrics.push({ lineEn: `We can ${wordsList[0]}!`, lineTh: `(ร้อง - เพลง!)`, chord: '' });
    dynamicLyrics.push({ lineEn: `We can ${wordsList[1]}!`, lineTh: `(เล่น - สนุก!)`, chord: '' });
  }
  const capitalizedWords = wordsList.map((w) => w.substring(0, 1).toUpperCase() + w.substring(1));
  dynamicLyrics.push({
    lineEn: `${capitalizedWords.join(', ')} now!`,
    lineTh: '(มี - ความ - สุข - จัง!)',
    chord: '',
  });

  dynamicLyrics.push({ lineEn: '[Outro]', lineTh: '', chord: '' });
  dynamicLyrics.push({
    lineEn: capitalizedWords.join('! ') + '!',
    lineTh: '(Jump! Jump! Go!)',
    chord: '',
  });

  const formattedWords: TargetWord[] = targetPhrases.map((p) => {
    const clean = p.trim().toLowerCase();
    return {
      word: p.trim(),
      thaiMeaning: p.trim(),
      phonetic: clean,
    };
  });

  const mainKeyword = targetPhrases[0] ? targetPhrases[0].trim() : 'Kids Song';

  return {
    titleEn: `${mainKeyword} Fun Song`,
    titleTh: `เพลง ${mainKeyword} แสนสนุก`,
    targetWords: formattedWords,
    lyrics: dynamicLyrics,
  };
}

export function resolveMediaUrl(rawUrl: string | null | undefined): string {
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
}

export async function resolveAndCacheSunoUrl(rawUrl: string | null | undefined): Promise<string> {
  if (!rawUrl) return '';
  const trimmed = rawUrl.trim();
  // Check if user passed a Task ID (e.g. efb5a890-e4b7-4d6a-9c28-91e8c280f2cb or UUID format)
  if (/^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/i.test(trimmed) || trimmed.length === 36) {
    try {
      console.log(`[Suno Link Resolver] 🔍 Fetching APIframe Task ID: ${trimmed}`);
      const sunoApiKey = (
        process.env.SUNO_API_KEY ||
        process.env.APIFRAME_KEY ||
        process.env.SUNO_KEY ||
        ''
      ).trim();

      const pollRes = await fetch('https://api.apiframe.ai/v2/fetch', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': sunoApiKey,
        },
        body: JSON.stringify({ task_id: trimmed }),
      });

      if (pollRes.ok) {
        const pollData = await pollRes.json();
        const foundUrl = extractAudioUrl(pollData);
        if (foundUrl) {
          console.log(`[Suno Link Resolver] 🎉 Extracted audio from Task ID: ${foundUrl}`);
          const audioFetch = await fetch(foundUrl);
          if (audioFetch.ok) {
            const buffer = new Uint8Array(await audioFetch.arrayBuffer());
            const key = `bilingual-songs/suno-task-${trimmed.substring(0, 8)}-${Date.now()}.mp3`;
            const minioUrl = await uploadToMinio(key, buffer, 'audio/mpeg');
            console.log(`[Suno Link Resolver] ✅ Cached Task ID audio to MinIO: ${minioUrl}`);
            return resolveMediaUrl(minioUrl);
          }
        }
      }
    } catch (e) {
      console.warn('[Suno Link Resolver] Failed to resolve Task ID:', e);
    }
  }

  // Check if user passed a Suno web page share link (e.g. https://suno.com/s/aZNMfxHpLnypFI06)
  if (trimmed.includes('suno.com/s/') || trimmed.includes('suno.com/song/')) {
    try {
      console.log(`[Suno Link Resolver] 🔍 Fetching Suno share page: ${trimmed}`);
      const pageRes = await fetch(trimmed, {
        headers: {
          'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      });

      if (pageRes.ok) {
        const html = await pageRes.text();
        const mp3Matches = html.match(/https:\/\/[^\s"\'<>]+\.mp3[^\s"\'<>]*/g);
        const mp3Url = mp3Matches?.find((m) => !m.includes('sil-100'))?.replace(/\\$/, '');

        if (mp3Url) {
          console.log(`[Suno Link Resolver] 🎉 Extracted real Suno MP3 CDN URL: ${mp3Url}`);
          const audioFetch = await fetch(mp3Url, {
            headers: {
              'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            },
          });
          if (audioFetch.ok) {
            const buffer = new Uint8Array(await audioFetch.arrayBuffer());
            const key = `bilingual-songs/suno-${Date.now()}.mp3`;
            const minioUrl = await uploadToMinio(key, buffer, 'audio/mpeg');
            console.log(`[Suno Link Resolver] ✅ Cached to MinIO: ${minioUrl}`);
            return resolveMediaUrl(minioUrl);
          }
        }
      }
    } catch (e) {
      console.warn('[Suno Link Resolver] Failed to resolve Suno web page URL:', e);
    }
  }

  return resolveMediaUrl(trimmed);
}

function extractAudioUrl(data: any): string | null {
  if (!data) return null;
  if (typeof data === 'string' && data.startsWith('http')) return data;

  const findUrlInObject = (obj: any): string | null => {
    if (!obj || typeof obj !== 'object') return null;
    if (typeof obj.audioUrl === 'string' && obj.audioUrl.startsWith('http')) return obj.audioUrl;
    if (typeof obj.audio_url === 'string' && obj.audio_url.startsWith('http')) return obj.audio_url;
    if (typeof obj.url === 'string' && obj.url.startsWith('http') && (obj.url.includes('.mp3') || obj.url.includes('/audio/'))) return obj.url;
    if (typeof obj.stream_url === 'string' && obj.stream_url.startsWith('http')) return obj.stream_url;

    if (Array.isArray(obj.tracks) && obj.tracks[0]) {
      const u = findUrlInObject(obj.tracks[0]);
      if (u) return u;
    }
    if (Array.isArray(obj.output) && obj.output[0]) {
      const u = findUrlInObject(obj.output[0]);
      if (u) return u;
    }
    if (obj.data) {
      const u = findUrlInObject(obj.data);
      if (u) return u;
    }
    if (obj.task_result) {
      const u = findUrlInObject(obj.task_result);
      if (u) return u;
    }
    if (obj.result) {
      const u = findUrlInObject(obj.result);
      if (u) return u;
    }

    return null;
  };

  return findUrlInObject(data);
}

function extractTaskId(data: any): string | null {
  if (!data) return null;
  if (typeof data === 'string' && data.length >= 20 && !data.startsWith('http')) return data;

  const candidate =
    data.task_id ||
    data.taskId ||
    data.id ||
    data.job_id ||
    data.jobId ||
    data.data?.task_id ||
    data.data?.taskId ||
    data.data?.id ||
    data.data?.job_id ||
    data.task?.id ||
    data.result?.task_id;

  return typeof candidate === 'string' ? candidate : null;
}

export function extractAllAudioUrls(data: any): string[] {
  if (!data) return [];
  const urls: string[] = [];

  const addCandidate = (u: any) => {
    if (typeof u === 'string' && u.startsWith('http') && !urls.includes(u)) {
      urls.push(u);
    }
  };

  const traverse = (obj: any) => {
    if (!obj || typeof obj !== 'object') return;

    if (Array.isArray(obj.tracks)) {
      obj.tracks.forEach((t: any) => {
        addCandidate(t?.audioUrl || t?.audio_url || t?.url);
      });
    }
    if (Array.isArray(obj.output)) {
      obj.output.forEach((t: any) => {
        if (typeof t === 'string') addCandidate(t);
        else addCandidate(t?.audioUrl || t?.audio_url || t?.url);
      });
    }
    if (Array.isArray(obj.data)) {
      obj.data.forEach((t: any) => {
        if (typeof t === 'string') addCandidate(t);
        else addCandidate(t?.audioUrl || t?.audio_url || t?.url);
      });
    }

    addCandidate(obj?.audioUrl || obj?.audio_url || obj?.stream_url || obj?.mp3_url);
    if (obj.data) traverse(obj.data);
    if (obj.output) traverse(obj.output);
    if (obj.task_result) traverse(obj.task_result);
    if (obj.result) traverse(obj.result);
  };

  traverse(data);

  if (urls.length === 0) {
    const single = extractAudioUrl(data);
    if (single) urls.push(single);
  }

  return urls;
}

export async function generateSunoSingingAudioResult(
  title: string,
  lyrics: LyricLine[],
  genre = 'Upbeat Nursery Rhyme'
): Promise<{ audioUrl: string; tracks: string[] }> {
  const sunoApiKey = (
    process.env.SUNO_API_KEY ||
    process.env.APIFRAME_KEY ||
    process.env.SUNO_KEY ||
    process.env.GOAPI_SUNO_KEY ||
    ''
  ).trim();

  const sunoApiUrl = (
    process.env.SUNO_API_URL || 'https://api.apiframe.ai/v2/music/generate'
  ).trim();

  const lyricText = lyrics
    .map((l) => {
      const en = l.lineEn.trim();
      const th = l.lineTh.trim();
      if (!en && !th) return '';
      if (en.startsWith('[')) return en;

      const cleanTh = th
        .replace(/[\(\)]/g, '')
        .replace(/แปล\s*-\s*ว่า\s*-\s*/gi, '')
        .replace(/แปลว่า\s*/gi, '')
        .trim();

      if (en && cleanTh) {
        return `${en}\n${cleanTh}`;
      }
      return en || cleanTh;
    })
    .filter(Boolean)
    .join('\n\n');

  const keyPrefix = sunoApiKey ? `${sunoApiKey.substring(0, 10)}...` : 'None';
  console.log(`[Suno AI Engine] Initializing API call to: ${sunoApiUrl}`);
  console.log(`[Suno AI Engine] SUNO_API_KEY in memory: ${keyPrefix}`);

  if (!sunoApiKey) {
    console.warn('[Suno AI Engine] ⚠️ SUNO_API_KEY is not set in .env!');
    throw new Error('กรุณาระบุ SUNO_API_KEY ในไฟล์ .env ก่อนสร้างไฟล์เสียงด้วย Suno AI');
  }

  console.log('[Suno AI Engine] 🚀 Sending single generation request to Suno Provider...');

  const styleHeader = genre ? `[Style: ${genre}]\n` : '';
  const combinedPrompt = `${styleHeader}${lyricText}`;

  const modelVersion = (process.env.SUNO_MODEL_VERSION || 'V5_5').trim();

  const payload = {
    model: 'suno',
    prompt: combinedPrompt.substring(0, 3000),
    sunoParams: {
      custom_mode: true,
      model_version: modelVersion,
    },
  };

  const response = await fetch(sunoApiUrl, {
    method: 'POST',
    headers: {
      'X-API-Key': sunoApiKey,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  const responseText = await response.text();
  console.log(`[Suno AI Engine] Initial Response status: ${response.status}. Body: ${responseText}`);

  let data: any = null;
  try {
    data = JSON.parse(responseText);
  } catch (e) {
    throw new Error(`Suno Provider returned invalid response (Status: ${response.status})`);
  }

  if (!response.ok) {
    console.error('[Suno AI Engine Error Response]:', responseText);
    const fullErrStr = typeof data === 'object' ? JSON.stringify(data) : responseText;
    throw new Error(`Suno API Error (${response.status}): ${fullErrStr}`);
  }

  let rawAudioUrls = extractAllAudioUrls(data);
  const taskId = extractTaskId(data);

  if (rawAudioUrls.length === 0 && taskId) {
    console.log(`[Suno AI Engine] ⏳ Async Task Created (ID: ${taskId}). Polling status...`);
    const maxAttempts = 60;
    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      await new Promise((res) => setTimeout(res, 3000));
      try {
        const fetchUrl = sunoApiUrl.includes('apiframe.ai')
          ? 'https://api.apiframe.ai/v2/fetch'
          : `https://api.goapi.ai/api/v1/task/${taskId}`;

        const pollRes = await fetch(fetchUrl, {
          method: fetchUrl.includes('apiframe.ai') ? 'POST' : 'GET',
          headers: {
            'X-API-Key': sunoApiKey,
            'Authorization': sunoApiKey.startsWith('Bearer ') ? sunoApiKey : `Bearer ${sunoApiKey}`,
            'Content-Type': 'application/json',
          },
          body: fetchUrl.includes('apiframe.ai') ? JSON.stringify({ task_id: taskId }) : undefined,
        });

        const pollText = await pollRes.text();
        console.log(`[Suno AI Engine Poll ${attempt}/${maxAttempts}] HTTP ${pollRes.status}: ${pollText.substring(0, 300)}`);

        let foundUrls: string[] = [];

        if (pollRes.ok) {
          try {
            const pollData = JSON.parse(pollText);
            foundUrls = extractAllAudioUrls(pollData);
          } catch {}
        }

        // Direct APIframe CDN pattern check fallback during polling (runs unconditionally)
        if (foundUrls.length === 0 && taskId && (taskId.length === 36 || taskId.includes('-'))) {
          const candidate0 = `https://cdn2.apiframe.ai/audio/${taskId}-0.mp3`;
          const candidate1 = `https://cdn2.apiframe.ai/audio/${taskId}-1.mp3`;

          try {
            const head0 = await fetch(candidate0, { method: 'HEAD' });
            if (head0.ok) foundUrls.push(candidate0);
          } catch {}

          try {
            const head1 = await fetch(candidate1, { method: 'HEAD' });
            if (head1.ok) foundUrls.push(candidate1);
          } catch {}
        }

        if (foundUrls.length > 0) {
          rawAudioUrls = foundUrls;
          console.log(`[Suno AI Engine] ✅ Found ${foundUrls.length} audio track(s) on attempt ${attempt}:`, foundUrls);
          break;
        }
      } catch (pollErr) {
        console.warn(`[Suno AI Engine] Poll attempt ${attempt} warning:`, pollErr);
      }
    }
  }

  if (rawAudioUrls.length === 0) {
    throw new Error(`ไม่ได้รับไฟล์เสียง MP3 จาก Suno API ภายใน 3 นาที (Task ID: ${taskId || 'Unknown'}) โปรดลองกดอีกครั้ง`);
  }

  // Download and cache all audio tracks into MinIO storage
  const cachedTracks: string[] = [];
  const cleanTitle = (title || 'suno-song').toLowerCase().replace(/[^a-z0-9_-]/g, '_');

  for (let idx = 0; idx < rawAudioUrls.length; idx++) {
    const rawUrl = rawAudioUrls[idx];
    try {
      console.log(`[Suno AI Engine] 📦 Caching track ${idx + 1}/${rawAudioUrls.length} to local MinIO...`);
      const audioFetch = await fetch(rawUrl);
      if (audioFetch.ok) {
        const buffer = new Uint8Array(await audioFetch.arrayBuffer());
        const key = `bilingual-songs/suno-${cleanTitle}-track${idx + 1}-${Date.now()}.mp3`;
        const minioUrl = await uploadToMinio(key, buffer, 'audio/mpeg');
        cachedTracks.push(resolveMediaUrl(minioUrl));
      } else {
        cachedTracks.push(resolveMediaUrl(rawUrl));
      }
    } catch (dlErr) {
      console.warn(`[Suno AI Engine] Track ${idx + 1} MinIO cache warning:`, dlErr);
      cachedTracks.push(resolveMediaUrl(rawUrl));
    }
  }

  return {
    audioUrl: cachedTracks[0] || '',
    tracks: cachedTracks,
  };
}

export async function generateSunoSingingAudio(
  title: string,
  lyrics: LyricLine[],
  genre = 'Upbeat Nursery Rhyme'
): Promise<string> {
  const result = await generateSunoSingingAudioResult(title, lyrics, genre);
  return result.audioUrl;
}

export async function getAllBilingualSongs(publishedOnly = false): Promise<BilingualSong[]> {
  await ensureBilingualSongTable();
  const rows = publishedOnly
    ? await prisma.$queryRaw<Array<{
        id: string;
        title_en: string;
        title_th: string;
        genre: string;
        target_words: unknown;
        lyrics: unknown;
        audio_url: string | null;
        cover_url: string | null;
        is_published: boolean;
        created_at: Date;
        updated_at: Date;
      }>>`
        SELECT * FROM bilingual_song
        WHERE is_published = true
        ORDER BY created_at DESC
      `
    : await prisma.$queryRaw<Array<{
        id: string;
        title_en: string;
        title_th: string;
        genre: string;
        target_words: unknown;
        lyrics: unknown;
        audio_url: string | null;
        cover_url: string | null;
        is_published: boolean;
        created_at: Date;
        updated_at: Date;
      }>>`
        SELECT * FROM bilingual_song
        ORDER BY created_at DESC
      `;

  return rows.map((r) => ({
    id: r.id,
    titleEn: r.title_en,
    titleTh: r.title_th,
    genre: r.genre,
    targetWords: (Array.isArray(r.target_words) ? r.target_words : []) as TargetWord[],
    lyrics: (Array.isArray(r.lyrics) ? r.lyrics : []) as LyricLine[],
    audioUrl: r.audio_url,
    coverUrl: r.cover_url || 'asset:assets/images/song_cover_default.png',
    isPublished: r.is_published,
    createdAt: r.created_at.toISOString(),
    updatedAt: r.updated_at.toISOString(),
  }));
}

export async function getBilingualSongById(id: string): Promise<BilingualSong | null> {
  await ensureBilingualSongTable();
  const rows = await prisma.$queryRaw<Array<{
    id: string;
    title_en: string;
    title_th: string;
    genre: string;
    target_words: unknown;
    lyrics: unknown;
    audio_url: string | null;
    cover_url: string | null;
    is_published: boolean;
    created_at: Date;
    updated_at: Date;
  }>>`
    SELECT * FROM bilingual_song WHERE id = ${id}::uuid LIMIT 1
  `;
  if (rows.length === 0) return null;
  const r = rows[0];
  return {
    id: r.id,
    titleEn: r.title_en,
    titleTh: r.title_th,
    genre: r.genre,
    targetWords: (Array.isArray(r.target_words) ? r.target_words : []) as TargetWord[],
    lyrics: (Array.isArray(r.lyrics) ? r.lyrics : []) as LyricLine[],
    audioUrl: r.audio_url,
    coverUrl: r.cover_url,
    isPublished: r.is_published,
    createdAt: r.created_at.toISOString(),
    updatedAt: r.updated_at.toISOString(),
  };
}
