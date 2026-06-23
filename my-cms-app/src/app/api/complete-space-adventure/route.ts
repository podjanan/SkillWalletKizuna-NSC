import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';
import { prisma } from '@/lib/prisma';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const {
      childId,
      totalScoreEarned,
      maxScore,
      detectedObjects,
      completedItems,
      scorePerItem,
      timerLimit,
      timeSpent,
    } = body;

    if (!childId) {
      return NextResponse.json(
        { error: 'Missing required field: childId is required' },
        { status: 400 },
      );
    }

    const auth = await getAuthenticatedParent(request);
    if (auth.error) return auth.error;

    const { parent } = auth;

    const childRelation = await prisma.parent_and_child.findFirst({
      where: { parent_id: parent.parent_id, child_id: childId },
    });

    if (!childRelation) {
      return NextResponse.json(
        { error: 'Child not found or does not belong to this parent' },
        { status: 403 },
      );
    }

    const child = await prisma.child.findUnique({
      where: { child_id: childId },
      select: { wallet: true, update_wallet: true },
    });

    if (!child) {
      return NextResponse.json(
        { error: 'Failed to fetch child data' },
        { status: 500 },
      );
    }

    const scoreToAdd = Number(totalScoreEarned) || 0;
    const currentWallet = Number(child.wallet) || 0;
    const currentUpdateWallet = Number(child.update_wallet) || 0;

    const activityRecord = await prisma.$transaction(async (tx) => {
      const record = await tx.activity_record.create({
        data: {
          parent_id: parent.parent_id,
          child_id: childId,
          activity_id: null,
          point: scoreToAdd,
          time_spent: timeSpent || null,
          date: new Date(),
          segment_results: (Array.isArray(completedItems) ? completedItems : null) as any,
          evidence: {
            type: 'space_adventure',
            category: 'LANGUAGE',
            difficulty: 'EASY',
            maxScore: Number(maxScore) || 100,
            detectedObjects: Array.isArray(detectedObjects) ? detectedObjects : [],
            scorePerItem: Number(scorePerItem) || 10,
            timerLimit: Number(timerLimit) || 60,
          },
        },
      });

      await tx.child.update({
        where: { child_id: childId },
        data: {
          wallet: currentWallet + scoreToAdd,
          update_wallet: currentUpdateWallet + scoreToAdd,
        },
      });

      return record;
    });

    return NextResponse.json({
      success: true,
      message: 'Space Adventure completed successfully!',
      activityRecord,
      scoreEarned: scoreToAdd,
      newWallet: currentWallet + scoreToAdd,
    });
  } catch (error) {
    console.error('Complete space adventure error:', error);
    return NextResponse.json(
      {
        error: 'Internal server error',
        details: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 },
    );
  }
}
