// src/app/api/delete-medal/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';
import { prisma } from '@/lib/prisma';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { medalsId } = body;

    if (!medalsId) {
      return NextResponse.json({ error: 'Missing required field: medalsId' }, { status: 400 });
    }

    const auth = await getAuthenticatedParent(request);
    if (auth.error) return auth.error;

    const { parent } = auth;

    // Verify this medal belongs to this parent
    const link = await prisma.parent_and_medals.findFirst({
      where: { parent_id: parent.parent_id, medals_id: medalsId },
    });

    if (!link) {
      return NextResponse.json(
        { error: 'Medal not found or does not belong to this parent' },
        { status: 403 }
      );
    }

    await prisma.$transaction(async (tx) => {
      await tx.parent_and_medals.deleteMany({ where: { medals_id: medalsId } });
      await tx.medals.delete({ where: { id: medalsId } });
    });

    return NextResponse.json({ success: true, message: 'Medal deleted successfully' });
  } catch (error) {
    console.error('Delete medal error:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
