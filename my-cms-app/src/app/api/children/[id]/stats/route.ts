import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';
import { prisma } from '@/lib/prisma';

type RouteContext = { params: Promise<{ id: string }> };

/**
 * GET /api/children/[id]/stats
 */
export async function GET(request: NextRequest, context: RouteContext) {
  const auth = await getAuthenticatedParent(request);
  if (auth.error) return auth.error;

  const { id: childId } = await context.params;

  try {
    const child = await prisma.child.findUnique({
      where: { child_id: childId },
      select: { wallet: true, name_surname: true },
    });

    if (!child) {
      return NextResponse.json({ error: 'Child not found' }, { status: 404 });
    }

    const totalActivities = await prisma.activity_record.count({
      where: { child_id: childId },
    });

    const wallet = child.wallet != null ? Math.floor(Number(child.wallet)) : 0;

    return NextResponse.json({
      wallet,
      name: child.name_surname || '',
      totalActivities,
    });
  } catch (err: any) {
    return NextResponse.json(
      { error: 'Failed to get stats', details: err.message },
      { status: 500 }
    );
  }
}
