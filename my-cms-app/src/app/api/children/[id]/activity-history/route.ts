import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';
import { prisma } from '@/lib/prisma';

type RouteContext = { params: Promise<{ id: string }> };

/**
 * GET /api/children/[id]/activity-history
 */
export async function GET(request: NextRequest, context: RouteContext) {
  const auth = await getAuthenticatedParent(request);
  if (auth.error) return auth.error;

  const { id: childId } = await context.params;

  try {
    const records = await prisma.activity_record.findMany({
      where: { child_id: childId },
      include: {
        activity: {
          select: { name_activity: true, category: true, maxscore: true },
        },
      },
      orderBy: { created_at: 'desc' },
    });

    return NextResponse.json(records);
  } catch (err: any) {
    return NextResponse.json(
      { error: 'Failed to get activity history', details: err.message },
      { status: 500 }
    );
  }
}
