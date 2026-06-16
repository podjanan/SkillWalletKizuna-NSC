// src/app/api/fetch-video-data/route.ts

import { NextResponse } from 'next/server';

// Utility: ดึง Video ID จาก URL ของ YouTube
const extractYoutubeId = (url: string): string | null => {
    const regex = /(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/i;
    const match = url.match(regex);
    return match ? match[1] : null;
};

// ========== YouTube Transcript Fetcher (Innertube API) ==========
// Replicates what Python youtube-transcript-api does:
// 1. Fetch video page → get API key + cookies
// 2. POST innertube player API (ANDROID client) → get caption track URLs
// 3. Fetch timedtext XML → parse into segments

interface TranscriptSegment {
    start: number;
    end: number;
    text: string;
}

interface CaptionTrack {
    baseUrl: string;
    languageCode: string;
    kind?: string; // 'asr' = auto-generated
}

const INNERTUBE_CONTEXT = {
    client: {
        clientName: 'ANDROID',
        clientVersion: '20.10.38',
    }
};

async function fetchPageData(videoId: string): Promise<{ apiKey: string; cookies: string }> {
    const response = await fetch(`https://www.youtube.com/watch?v=${videoId}`, {
        headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept-Language': 'en-US,en;q=0.9',
        },
    });
    const html = await response.text();
    const cookies = (response.headers.getSetCookie?.() || []).map((c: string) => c.split(';')[0]).join('; ');

    const apiKeyMatch = html.match(/"INNERTUBE_API_KEY":"([^"]+)"/);
    const apiKey = apiKeyMatch ? apiKeyMatch[1] : 'AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8';

    return { apiKey, cookies };
}

async function fetchCaptionTracks(videoId: string, apiKey: string, cookies: string): Promise<CaptionTrack[]> {
    const response = await fetch(`https://www.youtube.com/youtubei/v1/player?key=${apiKey}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Cookie': cookies,
        },
        body: JSON.stringify({
            context: INNERTUBE_CONTEXT,
            videoId,
        }),
    });

    const data = await response.json();
    const captions = data?.captions?.playerCaptionsTracklistRenderer?.captionTracks;

    if (!captions || !Array.isArray(captions)) {
        console.log('No caption tracks from innertube player API');
        return [];
    }

    return captions.map((track: any) => ({
        baseUrl: track.baseUrl.replace('&fmt=srv3', ''),
        languageCode: track.languageCode,
        kind: track.kind,
    }));
}

function selectBestTrack(tracks: CaptionTrack[]): CaptionTrack | null {
    if (tracks.length === 0) return null;

    // Priority: manual English > auto English > any manual > any auto > first available
    const priorities = [
        (t: CaptionTrack) => t.languageCode === 'en' && t.kind !== 'asr',
        (t: CaptionTrack) => t.languageCode.startsWith('en') && t.kind !== 'asr',
        (t: CaptionTrack) => t.languageCode === 'en' && t.kind === 'asr',
        (t: CaptionTrack) => t.languageCode.startsWith('en') && t.kind === 'asr',
        (t: CaptionTrack) => t.kind !== 'asr',
        () => true,
    ];

    for (const predicate of priorities) {
        const match = tracks.find(predicate);
        if (match) return match;
    }

    return tracks[0];
}

function parseTranscriptXml(xml: string): TranscriptSegment[] {
    const segments: TranscriptSegment[] = [];
    const textRegex = /<text\s+start="([^"]*)"(?:\s+dur="([^"]*)")?[^>]*>([\s\S]*?)<\/text>/g;

    let match;
    while ((match = textRegex.exec(xml)) !== null) {
        const start = parseFloat(match[1]);
        const dur = match[2] ? parseFloat(match[2]) : 0;
        const rawText = match[3];

        const text = decodeHtmlEntities(rawText)
            .replace(/\n/g, ' ')
            .replace(/\s+/g, ' ')
            .trim();

        if (text) {
            segments.push({
                start: Math.round(start * 10) / 10,
                end: Math.round((start + dur) * 10) / 10,
                text,
            });
        }
    }

    return segments;
}

async function fetchTranscript(videoId: string): Promise<TranscriptSegment[]> {
    console.log(`Fetching transcript for video: ${videoId}`);

    // 1. Get API key and cookies from page
    const { apiKey, cookies } = await fetchPageData(videoId);

    // 2. Get caption tracks via innertube player API (ANDROID client)
    const tracks = await fetchCaptionTracks(videoId, apiKey, cookies);
    console.log(`Found ${tracks.length} caption tracks:`, tracks.map(t => `${t.languageCode}${t.kind === 'asr' ? ' (auto)' : ''}`));

    if (tracks.length === 0) {
        console.warn('No caption tracks available');
        return [];
    }

    // 3. Select best track (prefer manual English)
    const selectedTrack = selectBestTrack(tracks);
    if (!selectedTrack) return [];

    console.log(`Selected: ${selectedTrack.languageCode} ${selectedTrack.kind === 'asr' ? '(auto)' : '(manual)'}`);

    // 4. Check for PoToken requirement
    if (selectedTrack.baseUrl.includes('&exp=xpe')) {
        console.warn('PoToken required for this video, transcript may not be accessible');
    }

    // 5. Fetch timedtext XML
    const trackResp = await fetch(selectedTrack.baseUrl, {
        headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Cookie': cookies,
        },
    });
    const xml = await trackResp.text();

    if (!xml) {
        console.warn('Empty transcript response');
        return [];
    }

    // 6. Parse XML into segments
    const segments = parseTranscriptXml(xml);
    console.log(`Parsed ${segments.length} segments`);

    return segments;
}

// ========== Metadata Scraping ==========

async function scrapeMetadata(videoUrl: string): Promise<{ title: string; description: string }> {
    try {
        const response = await fetch(videoUrl, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                'Accept-Language': 'en-US,en;q=0.9',
            },
        });
        const html = await response.text();

        let title = '';
        let description = '';

        const playerMatch = html.match(/var\s+ytInitialPlayerResponse\s*=\s*(\{[\s\S]+?\});/);
        if (playerMatch) {
            try {
                const playerData = JSON.parse(playerMatch[1]);
                const videoDetails = playerData?.videoDetails;
                if (videoDetails) {
                    title = videoDetails.title || '';
                    description = videoDetails.shortDescription || '';
                }
            } catch { /* JSON parse failed, fallback below */ }
        }

        if (!title) {
            const titleMatch = html.match(/<meta\s+property="og:title"\s+content="([^"]*)"/)
                || html.match(/<meta\s+content="([^"]*)"\s+property="og:title"/);
            title = titleMatch ? titleMatch[1] : '[Auto Fetch Failed] Please enter Title manually.';
        }

        if (!description) {
            const descMatch = html.match(/<meta\s+property="og:description"\s+content="([^"]*)"/)
                || html.match(/<meta\s+content="([^"]*)"\s+property="og:description"/);
            description = descMatch ? descMatch[1] : '[Auto Fetch Failed] Please enter description manually.';
        }

        return {
            title: decodeHtmlEntities(title.trim()),
            description: decodeHtmlEntities(description.trim()),
        };
    } catch (e) {
        console.error('Metadata scrape error:', e);
        return {
            title: '[Auto Fetch Failed] Please enter Title manually.',
            description: `Metadata fetch failed. Please enter description manually.`,
        };
    }
}

function decodeHtmlEntities(text: string): string {
    return text
        .replace(/&amp;/g, '&')
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&quot;/g, '"')
        .replace(/&#39;/g, "'")
        .replace(/&#x27;/g, "'")
        .replace(/&#(\d+);/g, (_, num) => String.fromCharCode(parseInt(num)));
}

/**
 * @swagger
 * /api/fetch-video-data:
 *   post:
 *     tags:
 *       - Activities
 *     summary: ดึงข้อมูลวิดีโอและ Subtitle จาก YouTube
 *     description: |
 *       ดึงข้อมูลวิดีโอจาก YouTube พร้อม subtitle/transcript
 *
 *       **Features:**
 *       - ดึง Video Title, Description
 *       - ดึง Subtitle/Transcript (อังกฤษ)
 *       - รองรับทั้ง Auto-generated และ Manual subtitles
 *       - ใช้ YouTube Innertube API (ANDROID client)
 *
 *       **Supported URL Formats:**
 *       - `https://www.youtube.com/watch?v=VIDEO_ID`
 *       - `https://youtu.be/VIDEO_ID`
 *       - `https://www.youtube.com/embed/VIDEO_ID`
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - videoUrl
 *             properties:
 *               videoUrl:
 *                 type: string
 *                 description: YouTube Video URL
 *                 example: "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
 *     responses:
 *       200:
 *         description: ดึงข้อมูลสำเร็จ
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 videoId:
 *                   type: string
 *                 title:
 *                   type: string
 *                 description:
 *                   type: string
 *                 segments:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       start:
 *                         type: number
 *                       end:
 *                         type: number
 *                       text:
 *                         type: string
 *       400:
 *         description: Bad Request
 *       500:
 *         description: Internal Server Error
 */
export async function POST(request: Request) {
    try {
        const { videoUrl } = await request.json();

        const videoId = extractYoutubeId(videoUrl);

        if (!videoUrl || !videoId) {
            return NextResponse.json({ error: 'Invalid YouTube URL or Video ID not found.' }, { status: 400 });
        }

        // 1. ดึง Metadata
        const metadata = await scrapeMetadata(videoUrl);

        // 2. ดึง Transcript (innertube API - no npm dependency)
        let segments: TranscriptSegment[] = [];

        try {
            segments = await fetchTranscript(videoId);
        } catch (transcriptError: any) {
            console.error('Transcript fetch error:', transcriptError?.message || transcriptError);
        }

        return NextResponse.json({
            videoId,
            title: metadata.title,
            description: metadata.description,
            segments,
        });

    } catch (error) {
        console.error('Error in fetching video data:', error);
        return NextResponse.json(
            { error: `Fetch Error: ${error instanceof Error ? error.message : String(error)}` },
            { status: 500 }
        );
    }
}
