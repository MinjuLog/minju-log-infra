#!/usr/bin/env sh
set -e

MINIO_ALIAS=local
MINIO_ENDPOINT=${MINIO_ENDPOINT}
MINIO_USER=${MINIO_ACCESS_KEY}
MINIO_PASS=${MINIO_SECRET_KEY}
BUCKET=${MINIO_BUCKET_NAME}

echo "⏳ Waiting for MinIO..."
until mc alias set $MINIO_ALIAS $MINIO_ENDPOINT $MINIO_ACCESS_KEY $MINIO_SECRET_KEY 2>/dev/null; do
  sleep 2
done

echo "🪣 Ensure bucket exists: $BUCKET"
mc ls $MINIO_ALIAS/$MINIO_BUCKET_NAME >/dev/null 2>&1 || mc mb $MINIO_ALIAS/$MINIO_BUCKET_NAME

echo "📜 Apply public GET policy"
mc anonymous set-json /policy.json $MINIO_ALIAS/$MINIO_BUCKET_NAME

echo "✅ MinIO policy initialized"
