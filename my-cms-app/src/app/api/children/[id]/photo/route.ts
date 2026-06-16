// api/children/[id]/photo/route.ts
// อัปโหลดรูปโปรไฟล์ของเด็กไปยัง MinIO
// แล้วอัปเดต photo_url ในตาราง child

import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';
import { uploadToMinio } from '@/lib/minio';
import { prisma } from '@/lib/prisma';

type RouteContext = { params: Promise<{ id: string }> };

export async function POST(
  request: NextRequest,
  context: RouteContext,
) {
  const { id: childId } = await context.params;

  const auth = await getAuthenticatedParent(request);
  if ('error' in auth) {
    return NextResponse.json({ error: auth.error }, { status: 401 });
  }
  const { parent } = auth;

  // Verify this child belongs to this parent
  const link = await prisma.parent_and_child.findFirst({
    where: { parent_id: parent.parent_id, child_id: childId },
  });
  if (!link) {
    return NextResponse.json({ error: 'Child not found or access denied' }, { status: 403 });
  }

  const formData = await request.formData();
  const file = formData.get('photo') as File | null;

  if (!file) {
    return NextResponse.json({ error: 'photo field is required' }, { status: 400 });
  }

  const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
  if (!allowedTypes.includes(file.type)) {
    return NextResponse.json(
      { error: 'Unsupported file type. Use JPEG, PNG or WebP.' },
      { status: 400 },
    );
  }

  const MAX_SIZE = 5 * 1024 * 1024;
  if (file.size > MAX_SIZE) {
    return NextResponse.json({ error: 'File too large (max 5 MB)' }, { status: 400 });
  }

  try {
    const bytes = await file.arrayBuffer();
    const buffer = new Uint8Array(bytes);

    // path: children/{childId}/profile.jpg (overwrites previous)
    const key = `children/${childId}/profile.jpg`;
    const photoUrl = await uploadToMinio(key, buffer, file.type);

    await prisma.child.update({
      where: { child_id: childId },
      data: { photo_url: photoUrl },
    });

    return NextResponse.json({ success: true, photoUrl });
  } catch (error) {
    console.error('POST /api/children/[id]/photo error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
