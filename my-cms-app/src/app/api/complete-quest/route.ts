// src/app/api/complete-quest/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';
import { prisma } from '@/lib/prisma';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { childId, activityId, totalScoreEarned, segmentResults, evidence, timeSpent } = body;

    if (!childId || !activityId) {
      return NextResponse.json(
        { error: 'Missing required fields: childId and activityId are required' },
        { status: 400 }
      );
    }

    const auth = await getAuthenticatedParent(request);
    if (auth.error) return auth.error;

    const { parent } = auth;

    // Verify child belongs to this parent
    const childRelation = await prisma.parent_and_child.findFirst({
      where: { parent_id: parent.parent_id, child_id: childId },
    });

    if (!childRelation) {
      return NextResponse.json(
        { error: 'Child not found or does not belong to this parent' },
        { status: 403 }
      );
    }

    const child = await prisma.child.findUnique({
      where: { child_id: childId },
      select: { wallet: true, update_wallet: true },
    });

    if (!child) {
      return NextResponse.json({ error: 'Failed to fetch child data' }, { status: 500 });
    }

    const scoreToAdd = totalScoreEarned || 0;
    const currentWallet = Number(child.wallet) || 0;
    const currentUpdateWallet = Number(child.update_wallet) || 0;

    const activityRecord = await prisma.$transaction(async (tx) => {
      const record = await tx.activity_record.create({
        data: {
          parent_id: parent.parent_id,
          child_id: childId,
          activity_id: activityId,
          point: scoreToAdd,
          time_spent: timeSpent || null,
          date: new Date(),
          segment_results: segmentResults || null,
          evidence: evidence || null,
        },
      });

      await tx.child.update({
        where: { child_id: childId },
        data: {
          wallet: currentWallet + scoreToAdd,
          update_wallet: currentUpdateWallet + scoreToAdd,
        },
      });

      // Increment play count on the activity
      await tx.activity.update({
        where: { activity_id: activityId },
        data: { play_count: { increment: 1 } },
      }).catch(() => { /* ignore if activity not found */ });

      return record;
    });

    return NextResponse.json({
      success: true,
      message: 'Quest completed successfully!',
      activityRecord,
      scoreEarned: scoreToAdd,
      newWallet: currentWallet + scoreToAdd,
      segmentResults,
      evidence,
    });
  } catch (error) {
    console.error('Complete quest error:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
