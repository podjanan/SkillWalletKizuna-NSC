import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';
import { prisma } from '@/lib/prisma';

/**
 * GET /api/children
 * List children for authenticated parent.
 * Uses Prisma (direct DB) instead of supabase.from() to avoid Supabase REST latency.
 * Returns nested format matching Flutter's expected structure.
 */
export async function GET(request: NextRequest) {
  const auth = await getAuthenticatedParent(request);
  if (auth.error) return auth.error;

  const { parent } = auth;

  try {
    const rows = await prisma.parent_and_child.findMany({
      where: { parent_id: parent.parent_id },
      include: {
        child: {
          select: {
            child_id: true,
            name_surname: true,
            wallet: true,
            birthday: true,
            photo_url: true,
          },
        },
      },
    });

    // Transform to match Flutter's expected format:
    // [{ child_id, relationship, child: { child_id, name_surname, wallet, birthday } }]
    const result = rows
      .filter((r) => r.child !== null)
      .map((r) => ({
        child_id: r.child_id,
        relationship: r.relationship,
        child: {
          child_id: r.child!.child_id,
          name_surname: r.child!.name_surname,
          wallet: r.child!.wallet !== null ? Number(r.child!.wallet) : 0,
          birthday: r.child!.birthday?.toISOString() ?? null,
          photo_url: r.child!.photo_url ?? null,
        },
      }));

    return NextResponse.json(result);
  } catch (err: any) {
    return NextResponse.json(
      { error: 'Failed to fetch children', details: err.message },
      { status: 500 }
    );
  }
}

/**
 * POST /api/children
 * Create child + link to parent.
 * Replaces RPC 'create_child_and_link'.
 *
 * Body: { fullName, birthday, relationship? }
 */
export async function POST(request: NextRequest) {
  const auth = await getAuthenticatedParent(request);
  if (auth.error) return auth.error;

  const { parent } = auth;

  try {
    const body = await request.json();
    const { fullName, birthday, relationship } = body;

    if (!fullName) {
      return NextResponse.json({ error: 'fullName is required' }, { status: 400 });
    }

    // Create child and link to parent in a transaction
    const result = await prisma.$transaction(async (tx) => {
      const child = await tx.child.create({
        data: {
          name_surname: fullName,
          birthday: birthday ? new Date(birthday) : null,
          wallet: 0,
        },
      });
      await tx.parent_and_child.create({
        data: {
          parent_id: parent.parent_id,
          child_id: child.child_id,
          relationship: relationship || 'พ่อ/แม่',
        },
      });
      return child;
    });

    return NextResponse.json({ child_id: result.child_id, name_surname: result.name_surname }, { status: 201 });
  } catch (err: any) {
    return NextResponse.json(
      { error: 'Failed to create child', details: err.message },
      { status: 500 }
    );
  }
}
