import { NextRequest, NextResponse } from 'next/server';

const RESOLVE_TIMEOUT_MS = 5_000;
const OEMBED_TIMEOUT_MS = 8_000;
const RETRY_DELAY_MS = 750;
const RETRYABLE_STATUSES = new Set([429, 502, 503, 504]);

class UpstreamTimeoutError extends Error {
  constructor() {
    super('TikTok request timed out');
    this.name = 'UpstreamTimeoutError';
  }
}

function parseTikTokUrl(value: unknown): URL | null {
  if (typeof value !== 'string' || !value.trim()) return null;

  try {
    const url = new URL(value.trim());
    const hostname = url.hostname.toLowerCase();
    const isTikTokHost = hostname === 'tiktok.com' || hostname.endsWith('.tiktok.com');

    if (url.protocol !== 'https:' || !isTikTokHost) return null;
    url.hash = '';
    return url;
  } catch {
    return null;
  }
}

function isTimeoutError(error: unknown) {
  return error instanceof Error &&
    (error.name === 'TimeoutError' || error.name === 'AbortError');
}

async function fetchTikTokOEmbed(url: string) {
  const oEmbedUrl = `https://www.tiktok.com/oembed?url=${encodeURIComponent(url)}&maxwidth=600&maxheight=800`;

  for (let attempt = 0; attempt < 2; attempt += 1) {
    try {
      const response = await fetch(oEmbedUrl, {
        signal: AbortSignal.timeout(OEMBED_TIMEOUT_MS),
        headers: { 'User-Agent': 'Mozilla/5.0 (compatible; SkillWallet/1.0)' },
      });

      if (attempt === 0 && RETRYABLE_STATUSES.has(response.status)) {
        await new Promise((resolve) => setTimeout(resolve, RETRY_DELAY_MS));
        continue;
      }

      return response;
    } catch (error) {
      if (attempt === 0) {
        await new Promise((resolve) => setTimeout(resolve, RETRY_DELAY_MS));
        continue;
      }

      if (isTimeoutError(error)) throw new UpstreamTimeoutError();
      throw error;
    }
  }

  throw new Error('TikTok request failed');
}

/**
 * POST /api/tiktok-oembed
 * Proxy TikTok oEmbed API to avoid CORS issues from Flutter client.
 *
 * Body: { videoUrl: string }
 * Response: { thumbnailUrl, html, title, authorName }
 */
export async function POST(request: NextRequest) {
  try {
    let body: unknown;
    try {
      body = await request.json();
    } catch {
      return NextResponse.json({ error: 'Invalid JSON body' }, { status: 400 });
    }

    const videoUrl = parseTikTokUrl((body as { videoUrl?: unknown })?.videoUrl);
    if (!videoUrl) {
      return NextResponse.json(
        { error: 'A valid HTTPS TikTok videoUrl is required' },
        { status: 400 }
      );
    }

    // Resolve short URLs once. oEmbed still receives the original URL if the
    // redirect is slow or unavailable, so a temporary resolve failure is safe.
    let resolvedUrl = videoUrl.toString();
    if (!videoUrl.pathname.includes('/video/')) {
      try {
        const response = await fetch(videoUrl, {
          method: 'GET',
          redirect: 'follow',
          signal: AbortSignal.timeout(RESOLVE_TIMEOUT_MS),
          headers: { 'User-Agent': 'Mozilla/5.0 (compatible; SkillWallet/1.0)' },
        });
        const redirectedUrl = parseTikTokUrl(response.url);
        if (redirectedUrl?.pathname.includes('/video/')) {
          redirectedUrl.search = '';
          resolvedUrl = redirectedUrl.toString();
        }
      } catch (error) {
        console.warn('TikTok short URL resolution failed', {
          reason: error instanceof Error ? error.name : 'UnknownError',
        });
      }
    }

    const response = await fetchTikTokOEmbed(resolvedUrl);
    if (!response.ok) {
      console.warn('TikTok oEmbed returned an error', { status: response.status });
      return NextResponse.json(
        { error: 'TikTok is temporarily unavailable', upstreamStatus: response.status },
        { status: 502 }
      );
    }

    const data = await response.json();
    return NextResponse.json({
      thumbnailUrl: data.thumbnail_url || '',
      html: data.html || '',
      title: data.title || '',
      authorName: data.author_name || '',
    });
  } catch (error) {
    const timedOut = error instanceof UpstreamTimeoutError || isTimeoutError(error);
    console.error('TikTok oEmbed request failed', {
      reason: error instanceof Error ? error.name : 'UnknownError',
    });

    return NextResponse.json(
      {
        error: timedOut
          ? 'TikTok request timed out. Please check the network and try again.'
          : 'Could not connect to TikTok. Please try again later.',
      },
      { status: timedOut ? 504 : 502 }
    );
  }
}
