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
  const prompt = `You are a creative children's songwriter and language teacher.
Create a short, catchy bilingual song for kids ages 4-9 based on these target vocabulary words: "${phrasesStr}".

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

export async function resolveAndCacheSunoUrl(rawUrl: string | null | undefined): Promise<string> {
  if (!rawUrl) return '';
  const trimmed = rawUrl.trim();

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

export async function generateSunoSingingAudio(
  title: string,
  lyrics: LyricLine[],
  genre = 'Upbeat Nursery Rhyme'
): Promise<string> {
  const sunoApiKey = (process.env.SUNO_API_KEY || process.env.GOAPI_SUNO_KEY || '').trim();
  const useGoApi = process.env.USE_GOAPI === 'true'; // Set USE_GOAPI=true in .env if you top up credits

  // 1. High-Speed Free AI Vocal Synthesis Engine (Default - 0.5 sec speed, 100% Free)
  if (!useGoApi) {
    console.log('[AI Music Engine] 🎙️ Generating Free AI Vocal Audio (High Speed)...');
    try {
      const fullLyricsText = lyrics.map((l) => l.lineEn).join('. ');
      const ttsUrl = `https://translate.google.com/translate_tts?ie=UTF-8&q=${encodeURIComponent(fullLyricsText.substring(0, 300))}&tl=en&client=tw-ob`;

      const ttsFetch = await fetch(ttsUrl, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      });

      if (ttsFetch.ok) {
        const buffer = new Uint8Array(await ttsFetch.arrayBuffer());
        const cleanTitle = (title || 'kids-song').toLowerCase().replace(/[^a-z0-9_-]/g, '_');
        const key = `bilingual-songs/vocal-${cleanTitle}-${Date.now()}.mp3`;
        const minioUrl = await uploadToMinio(key, buffer, 'audio/mpeg');
        console.log(`[AI Music Engine] ✅ Free AI Vocal Audio generated & stored in MinIO: ${minioUrl}`);
        return resolveMediaUrl(minioUrl);
      }
    } catch (e) {
      console.error('[AI Music Engine] AI Vocal synthesis failed:', e);
    }
  }

  // 2. GoAPI External API fallback (when USE_GOAPI=true)
  const sunoTaskUrl = 'https://api.goapi.ai/api/v1/task';
  const lyricText = lyrics.map((l) => l.lineEn).join('\n');
  const promptStyle = `children nursery rhyme, upbeat acoustic guitar, happy female vocalist, cheerful 100bpm, ${genre}`;

  console.log(`[AI Music Engine] Initializing. SUNO_API_KEY present: ${Boolean(sunoApiKey)}`);

  if (!sunoApiKey) {
    console.warn('[AI Music Engine] ⚠️ SUNO_API_KEY is not set in .env! Using fallback demo audio.');
  } else {
    try {
      console.log(`[AI Music Engine] 🚀 Submitting Suno music task to GoAPI (${sunoTaskUrl})...`);
      const response = await fetch(sunoTaskUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': sunoApiKey,
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
        body: JSON.stringify({
          model: 'suno',
          task_type: 'music',
          input: {
            prompt: lyricText,
            tags: promptStyle,
            title: title,
            make_instrumental: false,
          },
        }),
      });

      const responseText = await response.text();
      console.log(`[AI Music Engine] GoAPI Task Creation status: ${response.status}. Body: ${responseText.substring(0, 300)}`);

      let data: any = null;
      try {
        data = JSON.parse(responseText);
      } catch {}

      if (response.ok && data?.code === 200) {
        const taskId = data?.data?.task_id;
        if (taskId) {
          console.log(`[AI Music Engine] ⏳ Task created successfully (ID: ${taskId}). Polling GoAPI for music completion...`);
          const pollUrl = `https://api.goapi.ai/api/v1/task/${taskId}`;
          let audioUrl = '';

          const maxAttempts = 40;
          for (let attempt = 1; attempt <= maxAttempts; attempt++) {
            await new Promise((res) => setTimeout(res, 3000));
            try {
              const pollRes = await fetch(pollUrl, {
                headers: {
                  'X-API-Key': sunoApiKey,
                  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                },
              });
              if (pollRes.ok) {
                const pollData = await pollRes.json();
                const taskObj = pollData?.data || {};
                const status = taskObj?.status;
                const output = taskObj?.output;

                console.log(`[AI Music Engine] Polling attempt ${attempt}/${maxAttempts}: status = ${status}`);

                if (status === 'completed' || status === 'SUCCESS' || output) {
                  if (Array.isArray(output) && output.length > 0) {
                    audioUrl = output[0]?.audio_url || output[0]?.stream_url || output[0]?.audio_url_list?.[0] || '';
                  } else if (typeof output === 'object' && output !== null) {
                    audioUrl =
                      output?.audio_url ||
                      output?.audio_url_list?.[0] ||
                      output?.songs?.[0]?.audio_url ||
                      output?.clips?.[0]?.audio_url ||
                      '';
                  } else if (typeof output === 'string') {
                    audioUrl = output;
                  }

                  if (audioUrl) {
                    console.log(`[AI Music Engine] 🎉 Audio ready! URL: ${audioUrl}`);
                    break;
                  }
                }

                if (status === 'failed' || status === 'FAILED') {
                  console.error('[AI Music Engine] ❌ GoAPI task failed:', taskObj?.error);
                  break;
                }
              }
            } catch (pollErr) {
              console.warn('[AI Music Engine] Poll attempt error:', pollErr);
            }
          }

          if (audioUrl) {
            // Download audio MP3 and cache to MinIO
            try {
              const audioFetch = await fetch(audioUrl);
              if (audioFetch.ok) {
                const buffer = new Uint8Array(await audioFetch.arrayBuffer());
                const cleanTitle = title.toLowerCase().replace(/[^a-z0-9_-]/g, '_');
                const key = `bilingual-songs/${cleanTitle}-${Date.now()}.mp3`;
                const minioUrl = await uploadToMinio(key, buffer, 'audio/mpeg');
                return resolveMediaUrl(minioUrl);
              }
            } catch (dlErr) {
              console.warn('[AI Music Engine] Direct audio fetch failed, returning GoAPI audio URL:', dlErr);
            }
            return audioUrl;
          }
        }
      } else {
        console.error(`[AI Music Engine] GoAPI returned error status ${response.status}:`, responseText);
      }
    } catch (e) {
      console.error('[AI Music Engine] Exception during Suno API call:', e);
    }
  }

  // High-Quality Free AI Vocal Synthesis Engine (100% Free Forever)
  console.log('[AI Music Engine] 🎙️ Synthesizing clear English vocal audio for lyrics...');
  try {
    const fullLyricsText = lyrics.map((l) => l.lineEn).join('. ');
    const ttsUrl = `https://translate.google.com/translate_tts?ie=UTF-8&q=${encodeURIComponent(fullLyricsText.substring(0, 300))}&tl=en&client=tw-ob`;

    const ttsFetch = await fetch(ttsUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      },
    });

    if (ttsFetch.ok) {
      const buffer = new Uint8Array(await ttsFetch.arrayBuffer());
      const cleanTitle = (title || 'kids-song').toLowerCase().replace(/[^a-z0-9_-]/g, '_');
      const key = `bilingual-songs/vocal-${cleanTitle}-${Date.now()}.mp3`;
      const minioUrl = await uploadToMinio(key, buffer, 'audio/mpeg');
      console.log(`[AI Music Engine] ✅ Free AI Vocal Audio generated & stored in MinIO: ${minioUrl}`);
      return resolveMediaUrl(minioUrl);
    }
  } catch (e) {
    console.error('[AI Music Engine] AI Vocal synthesis failed:', e);
  }

  // Fallback demo audio track
  const demoAudio = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
  try {
    const audioFetch = await fetch(demoAudio);
    if (audioFetch.ok) {
      const buffer = new Uint8Array(await audioFetch.arrayBuffer());
      const cleanTitle = (title || 'kids-song').toLowerCase().replace(/[^a-z0-9_-]/g, '_');
      const key = `bilingual-songs/demo-${cleanTitle}-${Date.now()}.mp3`;
      const minioUrl = await uploadToMinio(key, buffer, 'audio/mpeg');
      return resolveMediaUrl(minioUrl);
    }
  } catch (e) {
    console.error('Fallback MinIO upload failed:', e);
  }

  return demoAudio;
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
