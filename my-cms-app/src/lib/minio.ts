import { S3Client, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

const s3 = new S3Client({
  region: 'us-east-1', // MinIO requires a region value but ignores it
  endpoint: process.env.MINIO_INTERNAL_URL!,
  forcePathStyle: true, // required for MinIO (path-style: endpoint/bucket/key)
  credentials: {
    accessKeyId: process.env.MINIO_ACCESS_KEY!,
    secretAccessKey: process.env.MINIO_SECRET_KEY!,
  },
});

export const BUCKET = process.env.MINIO_BUCKET ?? 'avatars';
const PUBLIC_URL = (process.env.MINIO_PUBLIC_URL ?? '').replace(/\/$/, '');

const publicS3 = new S3Client({
  region: 'us-east-1',
  endpoint: PUBLIC_URL,
  forcePathStyle: true,
  credentials: {
    accessKeyId: process.env.MINIO_ACCESS_KEY!,
    secretAccessKey: process.env.MINIO_SECRET_KEY!,
  },
});

/**
 * Upload a file to MinIO and return its public URL.
 * @param key  Storage path, e.g. "parents/{userId}/profile.jpg"
 */
export async function uploadToMinio(
  key: string,
  body: Uint8Array,
  contentType: string,
): Promise<string> {
  await s3.send(
    new PutObjectCommand({
      Bucket: BUCKET,
      Key: key,
      Body: body,
      ContentType: contentType,
    }),
  );

  // URL format: {PUBLIC_URL}/{bucket}/{key}?v={timestamp}
  return `${PUBLIC_URL}/${BUCKET}/${key}?v=${Date.now()}`;
}

/** Create a short-lived URL so large files can stream straight to MinIO. */
export async function createPresignedMinioUpload(
  key: string,
  contentType: string,
): Promise<{ uploadUrl: string; publicUrl: string }> {
  if (!PUBLIC_URL) throw new Error('MINIO_PUBLIC_URL is not configured');

  const uploadUrl = await getSignedUrl(
    publicS3,
    new PutObjectCommand({ Bucket: BUCKET, Key: key, ContentType: contentType }),
    { expiresIn: 15 * 60 },
  );
  const encodedKey = key.split('/').map(encodeURIComponent).join('/');
  return {
    uploadUrl,
    publicUrl: `${PUBLIC_URL}/${encodeURIComponent(BUCKET)}/${encodedKey}?v=${Date.now()}`,
  };
}

/** Read an object through the server-side MinIO connection. */
export async function getFromMinio(key: string): Promise<{
  body: Uint8Array;
  contentType: string;
}> {
  const object = await s3.send(new GetObjectCommand({ Bucket: BUCKET, Key: key }));
  if (!object.Body) throw new Error(`MinIO object has no body: ${key}`);

  return {
    body: await object.Body.transformToByteArray(),
    contentType: object.ContentType ?? 'application/octet-stream',
  };
}
