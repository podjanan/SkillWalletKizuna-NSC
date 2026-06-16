// app/api/activities/[id]/route.ts
import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

// Helper function to safely serialize JSON fields
function safeJsonSerialize(value: any) {
  if (value === null || value === undefined) return null;
  
  if (typeof value === 'string') {
    try {
      return JSON.parse(value);
    } catch {
      return value;
    }
  }
  
  return value;
}

// GET: ดึง activity ตาม ID
export async function GET(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const params = await context.params;
    
    const activity = await prisma.activity.findUnique({
      where: { activity_id: params.id },
      include: {
        parent: {
          select: {
            parent_id: true,
            name_surname: true,
            email: true,
          }
        },
        _count: { select: { activity_record: true } },
        activity_record: {
          take: 10,
          orderBy: { created_at: 'desc' },
          select: {
            ActivityRecord_id: true,
            point: true,
            date: true,
            created_at: true,
            child: { select: { name_surname: true } },
          },
        },
      }
    });

    if (!activity) {
      return NextResponse.json(
        { error: 'Activity not found' },
        { status: 404 }
      );
    }

    // แปลงเป็น format ที่ frontend ต้องการ
    const activityResponse = {
      // Format สำหรับ EditForm
      id: activity.activity_id,
      name: activity.name_activity,
      category: activity.category,
      content: activity.content,
      difficulty: activity.level_activity,
      maxScore: Number(activity.maxscore),
      description: activity.description_activity || '',
      videoUrl: activity.videourl || '',
      thumbnailUrl: activity.thumbnailurl || '',
      segments: safeJsonSerialize(activity.segments), // ✅ จัดการ JSON field
      playCount: activity.play_count ? Number(activity.play_count) : 0,
      parentId: activity.parent_id,
      createdAt: activity.created_at.toISOString(),
      updatedAt: activity.update_at.toISOString(),
      
      // Format สำหรับ admin UI
      activityId: activity.activity_id,
      nameActivity: activity.name_activity,
      descriptionActivity: activity.description_activity || '',
      responses: activity._count.activity_record,
      parent: activity.parent ? {
        id: activity.parent.parent_id,
        name: activity.parent.name_surname || 'N/A',
        email: activity.parent.email,
      } : null,
      recentRecords: activity.activity_record.map(r => ({
        id: r.ActivityRecord_id,
        childName: r.child?.name_surname || 'Unknown',
        scoreEarned: r.point ? Number(r.point) : 0,
        dateCompleted: (r.date ?? r.created_at).toISOString(),
        status: 'Completed',
      })),
    };

    return NextResponse.json(activityResponse);
  } catch (error: any) {
    const params = await context.params;
    console.error(`GET /api/activities/${params.id} error:`, error);
    return NextResponse.json(
      { error: 'Failed to fetch activity', details: error.message },
      { status: 500 }
    );
  }
}

// PATCH: แก้ไข activity
export async function PATCH(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const params = await context.params;
    const body = await request.json();

    // Build update data
    const updateData: any = {
      update_at: new Date()
    };

    if (body.name !== undefined) updateData.name_activity = body.name;
    if (body.category !== undefined) updateData.category = body.category;
    if (body.content !== undefined) updateData.content = body.content;
    if (body.difficulty !== undefined) updateData.level_activity = body.difficulty;
    if (body.maxScore !== undefined) updateData.maxscore = body.maxScore;
    if (body.description !== undefined) updateData.description_activity = body.description;
    if (body.videoUrl !== undefined) updateData.videourl = body.videoUrl;
    if (body.thumbnailUrl !== undefined) updateData.thumbnailurl = body.thumbnailUrl;
    if (body.isPublic !== undefined) updateData.is_public = body.isPublic;

    // Handle segments separately
    if (body.segments !== undefined) {
      updateData.segments = typeof body.segments === 'string'
        ? JSON.parse(body.segments)
        : body.segments;
    }

    const activity = await prisma.activity.update({
      where: { activity_id: params.id },
      data: updateData
    });

    // Response format
    const activityResponse = {
      activityId: activity.activity_id,
      id: activity.activity_id,
      nameActivity: activity.name_activity,
      name: activity.name_activity,
      category: activity.category,
      descriptionActivity: activity.description_activity || '',
      description: activity.description_activity || '',
      difficulty: activity.level_activity,
      maxScore: Number(activity.maxscore),
      videoUrl: activity.videourl || '',
      thumbnailUrl: activity.thumbnailurl || '',
      content: activity.content,
      segments: safeJsonSerialize(activity.segments),
      playCount: activity.play_count ? Number(activity.play_count) : 0,
      isPublic: activity.is_public,
      parentId: activity.parent_id,
      createdAt: activity.created_at.toISOString(),
      updatedAt: activity.update_at.toISOString(),
    };

    return NextResponse.json(activityResponse);
  } catch (error: any) {
    const params = await context.params;
    console.error(`PATCH /api/activities/${params.id} error:`, error);
    
    if (error.code === 'P2025') {
      return NextResponse.json(
        { error: 'Activity not found' },
        { status: 404 }
      );
    }

    return NextResponse.json(
      { error: 'Failed to update activity', details: error.message },
      { status: 400 }
    );
  }
}

// PUT: แก้ไข activity
export async function PUT(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const params = await context.params;
    const body = await request.json();

    // Build update data
    const updateData: any = {
      update_at: new Date()
    };

    if (body.name !== undefined) updateData.name_activity = body.name;
    if (body.category !== undefined) updateData.category = body.category;
    if (body.content !== undefined) updateData.content = body.content;
    if (body.difficulty !== undefined) updateData.level_activity = body.difficulty;
    if (body.maxScore !== undefined) updateData.maxscore = body.maxScore;
    if (body.description !== undefined) updateData.description_activity = body.description;
    if (body.videoUrl !== undefined) updateData.videourl = body.videoUrl;
    if (body.thumbnailUrl !== undefined) updateData.thumbnailurl = body.thumbnailUrl;
    
    // Handle segments
    if (body.segments !== undefined) {
      updateData.segments = typeof body.segments === 'string'
        ? JSON.parse(body.segments)
        : body.segments;
    }

    const activity = await prisma.activity.update({
      where: { activity_id: params.id },
      data: updateData
    });

    // Response format
    const activityResponse = {
      id: activity.activity_id,
      name: activity.name_activity,
      category: activity.category,
      content: activity.content,
      difficulty: activity.level_activity,
      maxScore: Number(activity.maxscore),
      description: activity.description_activity || '',
      videoUrl: activity.videourl || '',
      thumbnailUrl: activity.thumbnailurl || '',
      segments: safeJsonSerialize(activity.segments),
      playCount: activity.play_count ? Number(activity.play_count) : 0,
      parentId: activity.parent_id,
      createdAt: activity.created_at.toISOString(),
      updatedAt: activity.update_at.toISOString(),
    };

    return NextResponse.json(activityResponse);
  } catch (error: any) {
    const params = await context.params;
    console.error(`PUT /api/activities/${params.id} error:`, error);
    
    if (error.code === 'P2025') {
      return NextResponse.json(
        { error: 'Activity not found' },
        { status: 404 }
      );
    }

    return NextResponse.json(
      { error: 'Failed to update activity', details: error.message },
      { status: 400 }
    );
  }
}

// DELETE: ลบ activity
export async function DELETE(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const params = await context.params;
    
    await prisma.activity.delete({
      where: { activity_id: params.id }
    });

    return new NextResponse(null, { status: 204 });
  } catch (error: any) {
    const params = await context.params;
    console.error(`DELETE /api/activities/${params.id} error:`, error);
    
    if (error.code === 'P2025') {
      return NextResponse.json(
        { error: 'Activity not found' },
        { status: 404 }
      );
    }

    return NextResponse.json(
      { error: 'Failed to delete activity', details: error.message },
      { status: 400 }
    );
  }
}