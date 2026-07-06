import { NextRequest, NextResponse } from 'next/server';
import {
  deleteSpaceAdventureArea,
  getSpaceAdventureAreas,
  upsertSpaceAdventureArea,
} from '@/lib/ai-word-game';

function getErrorMessage(error: unknown) {
  return error instanceof Error ? error.message : 'Unexpected error';
}

export async function GET(request: NextRequest) {
  try {
    const activeOnly = request.nextUrl.searchParams.get('activeOnly') === 'true';
    const areas = await getSpaceAdventureAreas({ activeOnly });
    return NextResponse.json({ success: true, areas });
  } catch (e: unknown) {
    return NextResponse.json({ success: false, error: getErrorMessage(e) }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const area = await upsertSpaceAdventureArea({
      id: typeof body.id === 'string' ? body.id : undefined,
      name: String(body.name ?? ''),
      imageUrl: typeof body.imageUrl === 'string' ? body.imageUrl : '',
      items: body.items,
      active: Boolean(body.active ?? true),
      sortOrder: Number(body.sortOrder ?? 0),
    });
    return NextResponse.json({ success: true, area });
  } catch (e: unknown) {
    return NextResponse.json({ success: false, error: getErrorMessage(e) }, { status: 400 });
  }
}

export async function DELETE(request: NextRequest) {
  try {
    const id = request.nextUrl.searchParams.get('id');
    if (!id) {
      return NextResponse.json({ success: false, error: 'Area id is required.' }, { status: 400 });
    }

    await deleteSpaceAdventureArea(id);
    return NextResponse.json({ success: true });
  } catch (e: unknown) {
    return NextResponse.json({ success: false, error: getErrorMessage(e) }, { status: 500 });
  }
}
