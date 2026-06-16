// src/app/api/api-doc/route.ts

import { NextResponse } from 'next/server';
import { getApiDocs } from '@/lib/swagger';

export async function GET() {
  const spec = getApiDocs();
  
  return NextResponse.json(spec, {
    headers: {
      'Content-Type': 'application/json',
    },
  });
}