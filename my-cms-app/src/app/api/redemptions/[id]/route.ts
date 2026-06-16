import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';
import { prisma } from '@/lib/prisma';

/**
 * PATCH /api/redemptions/[id]
 * Apply behavior assessment result to an existing redemption.
 * Updates point_for_reward and adjusts child wallet in one transaction.
 *
 * Body: { behaviorDelta: number, adjustedCost: number }
 * - behaviorDelta: positive = good (refund), negative = bad (extra deduct), 0 = neutral
 * - adjustedCost: final cost to record (e.g., 47 instead of 50)
 */
export async function PATCH(
  request: NextRequest,
  context: { params: Promise<{ id: string }> }
) {
  const auth = await getAuthenticatedParent(request);
  if ('error' in auth) return auth.error;

  const { parent } = auth;
  const { id } = await context.params;
  const body = await request.json();
  const { behaviorDelta, adjustedCost } = body as {
    behaviorDelta?: number;
    adjustedCost?: number;
  };

  if (behaviorDelta == null || adjustedCost == null) {
    return NextResponse.json(
      { error: 'behaviorDelta and adjustedCost are required' },
      { status: 400 }
    );
  }

  const redemption = await prisma.redemption.findUnique({
    where: { redemption_id: id },
    select: { redemption_id: true, child_id: true, parent_id: true },
  });

  if (!redemption) {
    return NextResponse.json({ error: 'Redemption not found' }, { status: 404 });
  }

  if (redemption.parent_id !== parent.parent_id) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
  }

  const childId = redemption.child_id!;

  const child = await prisma.child.findUnique({
    where: { child_id: childId },
    select: { wallet: true },
  });

  if (!child) {
    return NextResponse.json({ error: 'Child not found' }, { status: 404 });
  }

  const currentWallet = Number(child.wallet) || 0;
  const newWallet = Math.max(0, Math.min(999999, currentWallet + Number(behaviorDelta)));

  await prisma.$transaction(async (tx) => {
    await tx.redemption.update({
      where: { redemption_id: id },
      data: { point_for_reward: adjustedCost },
    });
    await tx.child.update({
      where: { child_id: childId },
      data: { wallet: newWallet },
    });
  });

  return NextResponse.json({ success: true, newWallet, adjustedCost });
}
