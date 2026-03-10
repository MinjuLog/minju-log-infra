#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <build_tag>"
  echo "Example: $0 build-123 or $0 build-a1b2c3d"
  exit 1
fi

BUILD_TAG="$1"  # 예: build-123
REPO="jeongseho1/minjulog-feed"

# 프로젝트 루트에서 실행된다고 가정
CONF_DIR="./nginx/conf.d"
ACTIVE_UPSTREAM="${CONF_DIR}/upstream_feed_active.conf"
BLUE_UPSTREAM="${CONF_DIR}/upstream_feed_blue.tpl"
GREEN_UPSTREAM="${CONF_DIR}/upstream_feed_green.tpl"

# compose 서비스명
BLUE_SVC="feed-blue"
GREEN_SVC="feed-green"

# nginx 컨테이너 이름 (권장: compose에 container_name으로 고정)
NGINX_CONTAINER="${NGINX_CONTAINER:-minjulog-nginx}"

# nginx 컨테이너 내부에서 접근 가능한 헬스 URL
BLUE_HEALTH_URL="${BLUE_HEALTH_URL:-http://feed-blue:8080/health}"
GREEN_HEALTH_URL="${GREEN_HEALTH_URL:-http://feed-green:8080/health}"

RETRIES="${RETRIES:-30}"
SLEEP_SEC="${SLEEP_SEC:-1}"

log() { echo "[$(date '+%F %T')] $*"; }

current_color() {
  if grep -q "feed-blue:8080" "$ACTIVE_UPSTREAM"; then
    echo "blue"
  elif grep -q "feed-green:8080" "$ACTIVE_UPSTREAM"; then
    echo "green"
  else
    echo "unknown"
  fi
}

wait_healthy_from_nginx() {
  local url="$1"
  local name="$2"

  log "health check start: $name $url"
  for ((i=1; i<=RETRIES; i++)); do
    if docker exec "$NGINX_CONTAINER" sh -lc "wget -qO- --timeout=2 '$url' >/dev/null"; then
      log "health check ok: $name"
      return 0
    fi
    log "health check retry $i/$RETRIES: $name"
    sleep "$SLEEP_SEC"
  done

  log "health check failed: $name"
  return 1
}

reload_nginx() {
  log "nginx -t"
  docker exec "$NGINX_CONTAINER" nginx -t
  log "nginx reload"
  docker exec "$NGINX_CONTAINER" nginx -s reload
}

switch_upstream() {
  local next="$1"
  local name="$2"

  log "switch upstream_feed_active.conf -> $name"
  cp "$next" "$ACTIVE_UPSTREAM"
  reload_nginx
}

main() {
  local cur inactive_color inactive_svc inactive_upstream inactive_health
  cur="$(current_color)"
  log "current active: $cur"

  if [[ "$cur" == "blue" ]]; then
    inactive_color="green"
    inactive_svc="$GREEN_SVC"
    inactive_upstream="$GREEN_UPSTREAM"
    inactive_health="$GREEN_HEALTH_URL"
  else
    inactive_color="blue"
    inactive_svc="$BLUE_SVC"
    inactive_upstream="$BLUE_UPSTREAM"
    inactive_health="$BLUE_HEALTH_URL"
  fi

  log "deploying build tag: ${REPO}:${BUILD_TAG} to inactive: $inactive_color"

  # 1) 버전 태그 이미지 pull
  docker pull "${REPO}:${BUILD_TAG}"

  # 2) inactive 색 태그로 retag (compose는 :blue/:green을 사용하므로 여기를 업데이트)
  docker tag "${REPO}:${BUILD_TAG}" "${REPO}:${inactive_color}"

  # 선택: 태그 정리 (원치 않으면 제거)
  # docker image prune -f

  # 3) inactive 컨테이너만 recreate
  log "recreate service: $inactive_svc"
  docker compose --env-file .env up -d --no-deps --force-recreate "$inactive_svc"

  # 4) 헬스체크 OK면 스위치
  wait_healthy_from_nginx "$inactive_health" "$inactive_color"

  # 5) upstream 스위치 + nginx reload
  switch_upstream "$inactive_upstream" "$inactive_color"

  log "done. active is now: $inactive_color"
}

main