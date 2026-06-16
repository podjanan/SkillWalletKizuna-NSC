// src/app/api/redeem-medal/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';
import { prisma } from '@/lib/prisma';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { childId, medalsId, cost } = body;

    if (!childId || !medalsId || cost == null) {
      return NextResponse.json(
        { error: 'Missing required fields: childId, medalsId, and cost are required' },
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
      select: { wallet: true },
    });

    if (!child) {
      return NextResponse.json({ error: 'Failed to fetch child data' }, { status: 500 });
    }

    const currentWallet = Number(child.wallet) || 0;
    const redeemCost = Number(cost);

    if (currentWallet < redeemCost) {
      return NextResponse.json(
        {
          success: false,
          error: `Not enough points. Need ${redeemCost} but only have ${currentWallet}`,
          currentWallet,
        },
        { status: 400 }
      );
    }

    const newWallet = currentWallet - redeemCost;

    let redemptionId: string;

    await prisma.$transaction(async (tx) => {
      await tx.child.update({
        where: { child_id: childId },
        data: { wallet: newWallet },
      });
      const redemption = await tx.redemption.create({
        data: {
          child_id: childId,
          medals_id: medalsId,
          parent_id: parent.parent_id,
          point_for_reward: redeemCost,
          date_redemption: new Date(),
        },
        select: { redemption_id: true },
      });
      redemptionId = redemption.redemption_id;
    });

    return NextResponse.json({
      success: true,
      message: 'Medal redeemed successfully!',
      newWallet,
      cost: redeemCost,
      redemptionId: redemptionId!,
    });
  } catch (error) {
    console.error('Redeem medal error:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
