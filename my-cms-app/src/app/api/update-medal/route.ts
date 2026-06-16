// src/app/api/update-medal/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';
import { prisma } from '@/lib/prisma';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { medalsId, name, cost } = body;

    if (!medalsId || !name || cost == null) {
      return NextResponse.json(
        { error: 'Missing required fields: medalsId, name, and cost are required' },
        { status: 400 }
      );
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

    await prisma.medals.update({
      where: { id: medalsId },
      data: { name_medals: name, point_medals: Number(cost) },
    });

    return NextResponse.json({ success: true, message: 'Medal updated successfully' });
  } catch (error) {
    console.error('Update medal error:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
