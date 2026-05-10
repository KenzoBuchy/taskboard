#!/bin/sh
set -e

IMAGE="ghcr.io/kenzobucky/taskboard:latest"
CONTAINER="taskboard-app"
NETWORK="taskboard-net"

echo "==> Logging in to GHCR..."
echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin

echo "==> Pulling latest image..."
docker pull "$IMAGE"

echo "==> Stopping existing container (if any)..."
docker stop "$CONTAINER" 2>/dev/null || true
docker rm "$CONTAINER" 2>/dev/null || true

echo "==> Starting new container..."
docker run -d \
  --name "$CONTAINER" \
  --network "$NETWORK" \
  --restart unless-stopped \
  -p 3000:3000 \
  -e DATABASE_URL="postgresql://taskboard:taskboard123@postgres:5432/taskboard" \
  -e JWT_SECRET="${JWT_SECRET:-change-me-in-production}" \
  "$IMAGE"

echo "==> Waiting for healthcheck..."
for i in $(seq 1 15); do
  status=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER" 2>/dev/null || echo "starting")
  echo "    Status: $status (attempt $i/15)"
  if [ "$status" = "healthy" ]; then
    echo "==> Deployment successful — app is healthy"
    exit 0
  fi
  sleep 3
done

echo "==> Healthcheck failed — deployment unsuccessful"
exit 1
