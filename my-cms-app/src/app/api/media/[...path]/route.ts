import { NextRequest, NextResponse } from 'next/server';

type RouteContext = {
  params: Promise<{ path: string[] }>;
};

export async function GET(request: NextRequest, context: RouteContext) {
  const { path } = await context.params;
  if (!path?.length || path.some((segment) => segment === '..')) {
    return NextResponse.json({ error: 'Invalid media path' }, { status: 400 });
  }

  const minioOrigin = (process.env.MINIO_INTERNAL_URL ?? '').replace(/\/$/, '');
  if (!minioOrigin) {
    return NextResponse.json(
      { error: 'Object storage is not configured' },
      { status: 503 },
    );
  }

  const objectPath = path.map(encodeURIComponent).join('/');
  const sourceUrl = `${minioOrigin}/${objectPath}${request.nextUrl.search}`;

  try {
    const source = await fetch(sourceUrl, { cache: 'no-store' });
    if (!source.ok || !source.body) {
      return NextResponse.json(
        { error: 'Media not found' },
        { status: source.status === 404 ? 404 : 502 },
      );
    }

    const headers = new Headers();
    headers.set(
      'Content-Type',
      source.headers.get('content-type') ?? 'application/octet-stream',
    );
    headers.set(
      'Cache-Control',
      source.headers.get('cache-control') ?? 'public, max-age=3600',
    );
    const contentLength = source.headers.get('content-length');
    if (contentLength) headers.set('Content-Length', contentLength);

    return new NextResponse(source.body, { status: 200, headers });
  } catch (error) {
    console.error('Media proxy error:', error);
    return NextResponse.json({ error: 'Unable to load media' }, { status: 502 });
  }
}
