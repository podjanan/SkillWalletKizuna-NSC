import { S3Client, PutObjectCommand, CreateBucketCommand, HeadBucketCommand, PutBucketPolicyCommand } from '@aws-sdk/client-s3';

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
