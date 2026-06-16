import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';
import { prisma } from '@/lib/prisma';

type RouteContext = { params: Promise<{ id: string }> };

async function verifyChildOwnership(parentId: string, childId: string): Promise<boolean> {
  const link = await prisma.parent_and_child.findFirst({
    where: { parent_id: parentId, child_id: childId },
  });
  return !!link;
}

/**
 * GET /api/children/[id]
 */
export async function GET(request: NextRequest, context: RouteContext) {
  const auth = await getAuthenticatedParent(request);
  if (auth.error) return auth.error;

  const { id: childId } = await context.params;
  const { parent } = auth;

  if (!await verifyChildOwnership(parent.parent_id, childId)) {
    return NextResponse.json({ error: 'Child not found' }, { status: 404 });
  }

  try {
    const child = await prisma.child.findUnique({
      where: { child_id: childId },
      select: { child_id: true, name_surname: true, wallet: true, birthday: true, photo_url: true },
    });
    if (!child) return NextResponse.json({ error: 'Child not found' }, { status: 404 });
    return NextResponse.json(child);
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}

/**
 * PATCH /api/children/[id]
 * Body: { fullName?, birthday? }
 */
export async function PATCH(request: NextRequest, context: RouteContext) {
  const auth = await getAuthenticatedParent(request);
  if (auth.error) return auth.error;

  const { id: childId } = await context.params;
  const { parent } = auth;

  if (!await verifyChildOwnership(parent.parent_id, childId)) {
    return NextResponse.json({ error: 'Child not found' }, { status: 404 });
  }

  const body = await request.json();
  const updates: Record<string, any> = {};
  if (body.fullName) updates.name_surname = body.fullName;
  if (body.birthday) updates.birthday = new Date(body.birthday);
  if (body.photoUrl !== undefined) updates.photo_url = body.photoUrl;

  if (Object.keys(updates).length === 0) {
    return NextResponse.json({ error: 'No updates provided' }, { status: 400 });
  }

  try {
    const child = await prisma.child.update({
      where: { child_id: childId },
      data: updates,
      select: { child_id: true, name_surname: true, wallet: true, birthday: true, photo_url: true },
    });
    return NextResponse.json(child);
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}

/**
 * DELETE /api/children/[id]
 */
export async function DELETE(request: NextRequest, context: RouteContext) {
  const auth = await getAuthenticatedParent(request);
  if (auth.error) return auth.error;

  const { id: childId } = await context.params;
  const { parent } = auth;

  if (!await verifyChildOwnership(parent.parent_id, childId)) {
    return NextResponse.json({ error: 'Child not found' }, { status: 404 });
  }

  try {
    await prisma.parent_and_child.deleteMany({
      where: { child_id: childId, parent_id: parent.parent_id },
    });
    await prisma.child.delete({ where: { child_id: childId } });
    return NextResponse.json({ success: true });
  } catch (err: any) {
    return NextResponse.json(
      { error: 'Failed to delete child', details: err.message },
      { status: 500 }
    );
  }
}
