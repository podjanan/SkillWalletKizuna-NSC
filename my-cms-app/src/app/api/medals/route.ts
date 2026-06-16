import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';
import { prisma } from '@/lib/prisma';

/**
 * GET /api/medals
 * List medals for authenticated parent.
 */
export async function GET(request: NextRequest) {
  const auth = await getAuthenticatedParent(request);
  if (auth.error) return auth.error;

  const { parent } = auth;

  try {
    const rows = await prisma.parent_and_medals.findMany({
      where: { parent_id: parent.parent_id },
      include: {
        medals: {
          select: { id: true, name_medals: true, point_medals: true, created_at: true },
        },
      },
      orderBy: { created_at: 'desc' },
    });

    return NextResponse.json(rows);
  } catch (err: any) {
    return NextResponse.json(
      { error: 'Failed to fetch medals', details: err.message },
      { status: 500 }
    );
  }
}

/**
 * POST /api/medals
 * Create medal + link to parent.
 * Body: { name, cost }
 */
export async function POST(request: NextRequest) {
  const auth = await getAuthenticatedParent(request);
  if (auth.error) return auth.error;

  const { parent } = auth;

  try {
    const body = await request.json();
    const { name, cost } = body;

    if (!name) {
      return NextResponse.json({ error: 'name is required' }, { status: 400 });
    }
    if (cost === undefined || cost === null) {
      return NextResponse.json({ error: 'cost is required' }, { status: 400 });
    }

    const result = await prisma.$transaction(async (tx) => {
      const medal = await tx.medals.create({
        data: { name_medals: name, point_medals: Number(cost) },
      });
      await tx.parent_and_medals.create({
        data: { parent_id: parent.parent_id, medals_id: medal.id },
      });
      return medal;
    });

    return NextResponse.json({ id: result.id, name_medals: result.name_medals, point_medals: result.point_medals }, { status: 201 });
  } catch (err: any) {
    return NextResponse.json(
      { error: 'Failed to create medal', details: err.message },
      { status: 500 }
    );
  }
}
