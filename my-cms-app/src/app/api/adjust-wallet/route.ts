// src/app/api/adjust-wallet/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';
import { prisma } from '@/lib/prisma';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { childId, delta } = body;

    if (!childId || delta == null) {
      return NextResponse.json(
        { error: 'Missing required fields: childId and delta are required' },
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
    const deltaValue = Number(delta);
    const newWallet = Math.max(0, Math.min(999999, currentWallet + deltaValue));

    await prisma.child.update({
      where: { child_id: childId },
      data: { wallet: newWallet },
    });

    return NextResponse.json({ success: true, newWallet, delta: deltaValue });
  } catch (error) {
    console.error('Adjust wallet error:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
