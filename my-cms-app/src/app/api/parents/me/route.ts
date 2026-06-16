import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';
import { prisma } from '@/lib/prisma';

/**
 * GET /api/parents/me
 * Get current authenticated parent's profile.
 */
export async function GET(request: NextRequest) {
  const auth = await getAuthenticatedParent(request);

  if (auth.error) {
    return auth.error;
  }

  const baUser = await prisma.user.findUnique({
    where: { id: auth.user.id },
    select: { image: true },
  });

  return NextResponse.json({
    parentId: auth.parent.parent_id,
    nameSurname: auth.parent.name_surname,
    email: auth.parent.email,
    photoUrl: baUser?.image ?? null,
  });
}

/**
 * DELETE /api/parents/me
 * Delete current parent's account: removes activities, parent record, and auth user.
 */
export async function DELETE(request: NextRequest) {
  const auth = await getAuthenticatedParent(request);
  if (auth.error) return auth.error;

  const { parent, user } = auth;

  try {
    // 1. Delete activities created by this parent (onDelete: NoAction — must delete manually)
    await prisma.activity.deleteMany({
      where: { parent_id: parent.parent_id },
    });

    // 2. Delete parent record (cascades: activity_record, parent_and_child, parent_and_medals, redemption)
    await prisma.parent.delete({
      where: { parent_id: parent.parent_id },
    });

    // 3. Delete Better Auth user (cascades sessions and accounts)
    await prisma.user.delete({
      where: { id: user.id },
    });

    return NextResponse.json({ success: true });
  } catch (err: any) {
    return NextResponse.json(
      { error: 'Failed to delete account', details: err.message },
      { status: 500 }
    );
  }
}
