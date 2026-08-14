import { NextRequest, NextResponse } from 'next/server';
import {
  ensureBilingualSongTable,
  extractAllAudioUrls,
  generateBilingualLyricsWithQwen,
  generateSunoSingingAudio,
  generateSunoSingingAudioResult,
  getAllBilingualSongs,
  getBilingualSongById,
  resolveAndCacheSunoUrl,
  resolveMediaUrl,
} from '@/lib/bilingual-songs';
import { prisma } from '@/lib/prisma';

import { createPresignedMinioUpload, uploadToMinio } from '@/lib/minio';

const MAX_VIDEO_SIZE = 200 * 1024 * 1024;
const MAX_AUDIO_SIZE = 30 * 1024 * 1024;
const MAX_UPLOAD_REQUEST_SIZE = 201 * 1024 * 1024;

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');
    const publishedOnly = searchParams.get('publishedOnly') === 'true';

    if (id) {
      const song = await getBilingualSongById(id);
      if (!song) return NextResponse.json({ error: 'Song not found' }, { status: 404 });
      return NextResponse.json(song);
    }

    const songs = await getAllBilingualSongs(publishedOnly);
    return NextResponse.json(songs);
  } catch (e) {
    console.error('Failed to fetch bilingual songs:', e);
    return NextResponse.json({ error: 'Failed to fetch songs' }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    await ensureBilingualSongTable();

    // Handle audio/video file upload from computer
    const contentType = request.headers.get('content-type') || '';
    if (contentType.includes('multipart/form-data')) {
      const requestSize = Number(request.headers.get('content-length') || 0);
      if (requestSize > MAX_UPLOAD_REQUEST_SIZE) {
        return NextResponse.json(
          { error: 'ไฟล์วิดีโอต้องมีขนาดไม่เกิน 200 MB' },
          { status: 413 }
        );
      }

      let formData: FormData;
      try {
        formData = await request.formData();
      } catch (error) {
        console.error('Failed to parse bilingual song upload:', error);
        return NextResponse.json(
          { error: 'อ่านไฟล์อัปโหลดไม่สำเร็จ กรุณาตรวจสอบขนาดไฟล์แล้วลองใหม่' },
          { status: 400 }
        );
      }
      const file = formData.get('file') as File | null;
      const mediaType = String(formData.get('mediaType') || 'audio');
      if (!file) {
        return NextResponse.json({ error: 'No media file provided' }, { status: 400 });
      }

      const isVideo = mediaType === 'video';
      const maxFileSize = isVideo ? MAX_VIDEO_SIZE : MAX_AUDIO_SIZE;
      if (file.size > maxFileSize) {
        return NextResponse.json(
          { error: isVideo ? 'ไฟล์วิดีโอต้องมีขนาดไม่เกิน 200 MB' : 'ไฟล์เสียงต้องมีขนาดไม่เกิน 30 MB' },
          { status: 413 }
        );
      }
      const expectedPrefix = isVideo ? 'video/' : 'audio/';
      if (!file.type.startsWith(expectedPrefix)) {
        return NextResponse.json(
          { error: isVideo ? 'Please upload a video file' : 'Please upload an audio file' },
          { status: 400 }
        );
      }

      const arrayBuffer = await file.arrayBuffer();
      const buffer = new Uint8Array(arrayBuffer);
      const cleanName = file.name.toLowerCase().replace(/[^a-z0-9_.-]/g, '_');
      const key = `bilingual-songs/${isVideo ? 'dance-videos' : 'audio'}/upload-${Date.now()}-${cleanName}`;
      const minioUrl = await uploadToMinio(
        key,
        buffer,
        file.type || (isVideo ? 'video/mp4' : 'audio/mpeg')
      );
      const publicUrl = resolveMediaUrl(minioUrl);
      return NextResponse.json(isVideo ? { videoUrl: publicUrl } : { audioUrl: publicUrl });
    }

    const body = await request.json();
    const action = body.action as string;

    if (action === 'createVideoUpload') {
      const fileName = String(body.fileName || 'dance-video.mp4');
      const contentType = String(body.contentType || '');
      const fileSize = Number(body.fileSize || 0);
      if (!contentType.startsWith('video/')) {
        return NextResponse.json({ error: 'Please upload a video file' }, { status: 400 });
      }
      if (!Number.isFinite(fileSize) || fileSize <= 0 || fileSize > MAX_VIDEO_SIZE) {
        return NextResponse.json({ error: 'ไฟล์วิดีโอต้องมีขนาดไม่เกิน 200 MB' }, { status: 413 });
      }

      const cleanName = fileName.toLowerCase().replace(/[^a-z0-9_.-]/g, '_').slice(-120);
      const key = `bilingual-songs/dance-videos/upload-${Date.now()}-${cleanName || 'video.mp4'}`;
      return NextResponse.json(await createPresignedMinioUpload(key, contentType));
    }

    if (action === 'generateLyrics') {
      const phrases = Array.isArray(body.phrases)
        ? body.phrases.map(String)
        : String(body.phrases || '')
            .split(',')
            .map((s) => s.trim())
            .filter(Boolean);

      if (phrases.length === 0) {
        return NextResponse.json({ error: 'Target phrases/words are required' }, { status: 400 });
      }

      const genre = String(body.genre || 'Upbeat Nursery Rhyme');
      const lyricData = await generateBilingualLyricsWithQwen(phrases, genre);
      return NextResponse.json(lyricData);
    }

    if (action === 'generateAudio') {
      const title = String(body.title || 'Kids Bilingual Song');
      const lyrics = Array.isArray(body.lyrics) ? body.lyrics : [];
      const genre = String(body.genre || 'Upbeat Nursery Rhyme');

      if (lyrics.length === 0) {
        return NextResponse.json({ error: 'Lyrics are required to generate audio' }, { status: 400 });
      }

      try {
        const result = await generateSunoSingingAudioResult(title, lyrics, genre);
        return NextResponse.json({
          audioUrl: result.audioUrl,
          tracks: result.tracks,
        });
      } catch (err: any) {
        console.error('[API generateAudio error]:', err);
        return NextResponse.json(
          { error: err?.message || 'Failed to generate audio from Suno AI' },
          { status: 500 }
        );
      }
    }

    if (action === 'fetchTaskTracks') {
      const taskId = String(body.taskId || '').trim();
      if (!taskId) {
        return NextResponse.json({ error: 'TaskId is required' }, { status: 400 });
      }

      try {
        const sunoApiKey = (
          process.env.SUNO_API_KEY ||
          process.env.APIFRAME_KEY ||
          process.env.SUNO_KEY ||
          ''
        ).trim();

        let rawTracks: string[] = [];

        // 1. Query APIframe fetch API
        try {
          const pollRes = await fetch('https://api.apiframe.ai/v2/fetch', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'X-API-Key': sunoApiKey,
              'Authorization': sunoApiKey.startsWith('Bearer ') ? sunoApiKey : `Bearer ${sunoApiKey}`,
            },
            body: JSON.stringify({ task_id: taskId }),
          });

          if (pollRes.ok) {
            const pollData = await pollRes.json();
            rawTracks = extractAllAudioUrls(pollData);
          }
        } catch (e) {
          console.warn('[fetchTaskTracks poll error]:', e);
        }

        // 2. Direct APIframe CDN URL pattern fallback (task_id-0.mp3 and task_id-1.mp3)
        if (rawTracks.length === 0 && (taskId.length === 36 || taskId.includes('-'))) {
          const candidate0 = `https://cdn2.apiframe.ai/audio/${taskId}-0.mp3`;
          const candidate1 = `https://cdn2.apiframe.ai/audio/${taskId}-1.mp3`;

          try {
            const head0 = await fetch(candidate0, { method: 'HEAD' });
            if (head0.ok) rawTracks.push(candidate0);
          } catch {}

          try {
            const head1 = await fetch(candidate1, { method: 'HEAD' });
            if (head1.ok) rawTracks.push(candidate1);
          } catch {}
        }

        // 3. Cache valid audio tracks to local MinIO
        const cachedTracks: string[] = [];
        for (let idx = 0; idx < rawTracks.length; idx++) {
          const rawUrl = rawTracks[idx];
          try {
            const audioFetch = await fetch(rawUrl);
            if (audioFetch.ok) {
              const buffer = new Uint8Array(await audioFetch.arrayBuffer());
              const key = `bilingual-songs/suno-task-${taskId.substring(0, 8)}-tr${idx + 1}-${Date.now()}.mp3`;
              const minioUrl = await uploadToMinio(key, buffer, 'audio/mpeg');
              cachedTracks.push(resolveMediaUrl(minioUrl));
            } else {
              cachedTracks.push(resolveMediaUrl(rawUrl));
            }
          } catch (dlErr) {
            cachedTracks.push(resolveMediaUrl(rawUrl));
          }
        }

        return NextResponse.json({ tracks: cachedTracks });
      } catch (err: any) {
        return NextResponse.json({ error: err?.message || 'Failed to fetch Task tracks' }, { status: 500 });
      }
    }

    if (action === 'saveSong') {
      const { id, titleEn, titleTh, genre, targetWords, lyrics, audioUrl, danceVideoUrl, coverUrl, isPublished } = body;
      const cleanTitleEn = String(titleEn || '').trim();
      const cleanTitleTh = String(titleTh || '').trim();

      if (!cleanTitleEn || !cleanTitleTh) {
        return NextResponse.json({ error: 'English and Thai titles are required' }, { status: 400 });
      }

      // Resolve Suno share URLs to direct MinIO cached MP3 URLs
      const processedAudioUrl = audioUrl ? await resolveAndCacheSunoUrl(String(audioUrl)) : null;

      if (id) {
        // Update existing song
        await prisma.$executeRaw`
          UPDATE bilingual_song
          SET title_en = ${cleanTitleEn},
              title_th = ${cleanTitleTh},
              genre = ${String(genre || 'Upbeat Nursery Rhyme')},
              target_words = ${JSON.stringify(targetWords || [])}::jsonb,
              lyrics = ${JSON.stringify(lyrics || [])}::jsonb,
              audio_url = ${processedAudioUrl},
              dance_video_url = ${danceVideoUrl ? String(danceVideoUrl) : null},
              cover_url = ${coverUrl ? String(coverUrl) : null},
              is_published = ${typeof isPublished === 'boolean' ? isPublished : true},
              updated_at = CURRENT_TIMESTAMP
          WHERE id = ${String(id)}::uuid
        `;
        return NextResponse.json({ success: true, id, audioUrl: processedAudioUrl });
      } else {
        // Create new song
        const newId = crypto.randomUUID();
        await prisma.$executeRaw`
          INSERT INTO bilingual_song (id, title_en, title_th, genre, target_words, lyrics, audio_url, dance_video_url, cover_url, is_published, created_at, updated_at)
          VALUES (
            ${newId}::uuid,
            ${cleanTitleEn},
            ${cleanTitleTh},
            ${String(genre || 'Upbeat Nursery Rhyme')},
            ${JSON.stringify(targetWords || [])}::jsonb,
            ${JSON.stringify(lyrics || [])}::jsonb,
            ${processedAudioUrl},
            ${danceVideoUrl ? String(danceVideoUrl) : null},
            ${coverUrl ? String(coverUrl) : null},
            ${typeof isPublished === 'boolean' ? isPublished : true},
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
          )
        `;
        return NextResponse.json({ success: true, id: newId, audioUrl: processedAudioUrl });
      }
    }

    if (action === 'deleteSong') {
      const songId = String(body.id || '');
      if (!songId) return NextResponse.json({ error: 'Song ID required' }, { status: 400 });

      await prisma.$executeRaw`
        DELETE FROM bilingual_song WHERE id = ${songId}::uuid
      `;
      return NextResponse.json({ success: true });
    }

    return NextResponse.json({ error: 'Invalid action' }, { status: 400 });
  } catch (e) {
    console.error('Bilingual song API error:', e);
    return NextResponse.json({ error: 'Server error processing song request' }, { status: 500 });
  }
}
