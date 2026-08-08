import { NextRequest, NextResponse } from 'next/server';
import {
  ensureBilingualSongTable,
  generateBilingualLyricsWithQwen,
  generateSunoSingingAudio,
  getAllBilingualSongs,
  getBilingualSongById,
  resolveAndCacheSunoUrl,
  resolveMediaUrl,
} from '@/lib/bilingual-songs';
import { prisma } from '@/lib/prisma';

import { uploadToMinio } from '@/lib/minio';

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

    // Handle MP3 File Upload from computer
    const contentType = request.headers.get('content-type') || '';
    if (contentType.includes('multipart/form-data')) {
      const formData = await request.formData();
      const file = formData.get('file') as File | null;
      if (!file) {
        return NextResponse.json({ error: 'No audio file provided' }, { status: 400 });
      }

      const arrayBuffer = await file.arrayBuffer();
      const buffer = new Uint8Array(arrayBuffer);
      const cleanName = file.name.toLowerCase().replace(/[^a-z0-9_.-]/g, '_');
      const key = `bilingual-songs/upload-${Date.now()}-${cleanName}`;
      const minioUrl = await uploadToMinio(key, buffer, file.type || 'audio/mpeg');
      const publicUrl = resolveMediaUrl(minioUrl);
      return NextResponse.json({ audioUrl: publicUrl });
    }

    const body = await request.json();
    const action = body.action as string;

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

      const audioUrl = await generateSunoSingingAudio(title, lyrics, genre);
      return NextResponse.json({ audioUrl });
    }

    if (action === 'saveSong') {
      const { id, titleEn, titleTh, genre, targetWords, lyrics, audioUrl, coverUrl, isPublished } = body;
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
          INSERT INTO bilingual_song (id, title_en, title_th, genre, target_words, lyrics, audio_url, cover_url, is_published, created_at, updated_at)
          VALUES (
            ${newId}::uuid,
            ${cleanTitleEn},
            ${cleanTitleTh},
            ${String(genre || 'Upbeat Nursery Rhyme')},
            ${JSON.stringify(targetWords || [])}::jsonb,
            ${JSON.stringify(lyrics || [])}::jsonb,
            ${processedAudioUrl},
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
