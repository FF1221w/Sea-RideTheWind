#!/usr/bin/env bash
set -euo pipefail

timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  echo "[$(timestamp)] [entrypoint] $*"
}

SERVICE_NAME="${SERVICE_NAME:-unknown}"
API_ENABLED="${API_ENABLED:-0}"
RPC_ENABLED="${RPC_ENABLED:-0}"
API_WORKDIR="${API_WORKDIR:-}"
RPC_WORKDIR="${RPC_WORKDIR:-}"
API_BIN="${API_BIN:-/app/bin/api}"
RPC_BIN="${RPC_BIN:-/app/bin/rpc}"
API_CONFIG="${API_CONFIG:-}"
RPC_CONFIG="${RPC_CONFIG:-}"

ETCD_ADDR="${ETCD_ADDR:-}"
REDIS_ADDR="${REDIS_ADDR:-}"
POSTGRES_ADDR="${POSTGRES_ADDR:-}"
POSTGRES_PORT="${POSTGRES_PORT:-35432}"
POSTGRES_USER="${POSTGRES_USER:-admin}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}"
POSTGRES_DB="${POSTGRES_DB:-first_db}"
POSTGRES_ADDR="${POSTGRES_ADDR:-postgres}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
KAFKA_ADDR="${KAFKA_ADDR:-}"
MINIO_ADDR="${MINIO_ADDR:-}"
BEANSTALKD1_ADDR="${BEANSTALKD1_ADDR:-}"
BEANSTALKD2_ADDR="${BEANSTALKD2_ADDR:-}"
OTEL_ADDR="${OTEL_ADDR:-}"

mkdir -p /app/log /tmp/service-configs /app/service/like/rpc/data

require_file() {
  local f="$1"
  if [ ! -f "$f" ]; then
    log "missing file: $f"
    exit 1
  fi
}

patch_config() {
  local src="$1"
  local dst="$2"

  require_file "$src"
  cp "$src" "$dst"

  escape_sed_replacement() {
    printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
  }

  local postgres_addr_esc postgres_port_esc postgres_user_esc postgres_password_esc postgres_db_esc
  postgres_addr_esc="$(escape_sed_replacement "$POSTGRES_ADDR")"
  postgres_port_esc="$(escape_sed_replacement "$POSTGRES_PORT")"
  postgres_user_esc="$(escape_sed_replacement "$POSTGRES_USER")"
  postgres_password_esc="$(escape_sed_replacement "$POSTGRES_PASSWORD")"
  postgres_db_esc="$(escape_sed_replacement "$POSTGRES_DB")"

sed -i \
  -e "s#\${POSTGRES_ADDR}#${postgres_addr_esc}#g" \
  -e "s#\${POSTGRES_PORT}#${postgres_port_esc}#g" \
  -e "s#\${POSTGRES_USER}#${postgres_user_esc}#g" \
  -e "s#\${POSTGRES_PASSWORD}#${postgres_password_esc}#g" \
  -e "s#\${POSTGRES_DB}#${postgres_db_esc}#g" \
  -e "s#127\.0\.0\.1:32379#${ETCD_ADDR}#g" \
  -e "s#127\.0\.0\.1:36379#${REDIS_ADDR}#g" \
  -e "s#127\.0\.0\.1:6379#${REDIS_ADDR}#g" \
  -e "s#127\.0\.0\.1:39092#${KAFKA_ADDR}#g" \
  -e "s#127\.0\.0\.1:39000#${MINIO_ADDR}#g" \
  -e "s#127\.0\.0\.1:41300#${BEANSTALKD1_ADDR}#g" \
  -e "s#127\.0\.0\.1:41301#${BEANSTALKD2_ADDR}#g" \
  -e "s#Host: \"127\.0\.0\.1\"#Host: \"${POSTGRES_ADDR}\"#g" \
  -e "s#Host: 127\.0\.0\.1#Host: ${POSTGRES_ADDR}#g" \
  -e "s#@127\.0\.0\.1:35432#@${POSTGRES_ADDR}:${POSTGRES_PORT}#g" \
  -e "s#127\.0\.0\.1:35432#${POSTGRES_ADDR}:${POSTGRES_PORT}#g" \
  -e "s#175\.24\.130\.226:32379#${ETCD_ADDR}#g" \
  -e "s#host\.docker\.internal:32379#${ETCD_ADDR}#g" \
  -e "s#175\.24\.130\.226:36379#${REDIS_ADDR}#g" \
  -e "s#175\.24\.130\.226:6379#${REDIS_ADDR}#g" \
  -e "s#host\.docker\.internal:36379#${REDIS_ADDR}#g" \
  -e "s#175\.24\.130\.226:39092#${KAFKA_ADDR}#g" \
  -e "s#host\.docker\.internal:39092#${KAFKA_ADDR}#g" \
  -e "s#175\.24\.130\.226:39000#${MINIO_ADDR}#g" \
  -e "s#host\.docker\.internal:39000#${MINIO_ADDR}#g" \
  -e "s#175\.24\.130\.226:41300#${BEANSTALKD1_ADDR}#g" \
  -e "s#host\.docker\.internal:41300#${BEANSTALKD1_ADDR}#g" \
  -e "s#175\.24\.130\.226:41301#${BEANSTALKD2_ADDR}#g" \
  -e "s#host\.docker\.internal:41301#${BEANSTALKD2_ADDR}#g" \
  -e "s#Host: 175\.24\.130\.226:36379#Host: ${REDIS_ADDR}#g" \
  -e "s#Addr: 175\.24\.130\.226:36379#Addr: ${REDIS_ADDR}#g" \
  -e "s#Host: \"175\.24\.130\.226:36379\"#Host: \"${REDIS_ADDR}\"#g" \
  -e "s#Host: \"host\.docker\.internal:36379\"#Host: \"${REDIS_ADDR}\"#g" \
  -e "s#Host: \"http://175\.24\.130\.226\"#Host: \"${POSTGRES_ADDR}\"#g" \
  -e "s#Host: \"https://175\.24\.130\.226\"#Host: \"${POSTGRES_ADDR}\"#g" \
  -e "s#Host: \"http://host\.docker\.internal\"#Host: \"${POSTGRES_ADDR}\"#g" \
  -e "s#Host: \"https://host\.docker\.internal\"#Host: \"${POSTGRES_ADDR}\"#g" \
  -e "s#Host: \"175\.24\.130\.226\"#Host: \"${POSTGRES_ADDR}\"#g" \
  -e "s#Host: \"host\.docker\.internal\"#Host: \"${POSTGRES_ADDR}\"#g" \
  -e "s#Host: http://175\.24\.130\.226#Host: ${POSTGRES_ADDR}#g" \
  -e "s#Host: https://175\.24\.130\.226#Host: ${POSTGRES_ADDR}#g" \
  -e "s#Host: http://host\.docker\.internal#Host: ${POSTGRES_ADDR}#g" \
  -e "s#Host: https://host\.docker\.internal#Host: ${POSTGRES_ADDR}#g" \
  -e "s#Host: 175\.24\.130\.226#Host: ${POSTGRES_ADDR}#g" \
  -e "s#Host: host\.docker\.internal#Host: ${POSTGRES_ADDR}#g" \
  -e "s#Port: \"35432\"#Port: \"${POSTGRES_PORT}\"#g" \
  -e "s#port=35432#port=${POSTGRES_PORT}#g" \
  -e "s#host=http://175\.24\.130\.226 #host=${POSTGRES_ADDR} #g" \
  -e "s#host=https://175\.24\.130\.226 #host=${POSTGRES_ADDR} #g" \
  -e "s#host=http://host\.docker\.internal #host=${POSTGRES_ADDR} #g" \
  -e "s#host=https://host\.docker\.internal #host=${POSTGRES_ADDR} #g" \
  -e "s#host=175\.24\.130\.226 #host=${POSTGRES_ADDR} #g" \
  -e "s#host=host\.docker\.internal #host=${POSTGRES_ADDR} #g" \
  -e "s#@http://175\.24\.130\.226:35432#@${POSTGRES_ADDR}:${POSTGRES_PORT}#g" \
  -e "s#@https://175\.24\.130\.226:35432#@${POSTGRES_ADDR}:${POSTGRES_PORT}#g" \
  -e "s#@http://host\.docker\.internal:35432#@${POSTGRES_ADDR}:${POSTGRES_PORT}#g" \
  -e "s#@https://host\.docker\.internal:35432#@${POSTGRES_ADDR}:${POSTGRES_PORT}#g" \
  -e "s#@175\.24\.130\.226:35432#@${POSTGRES_ADDR}:${POSTGRES_PORT}#g" \
  -e "s#@host\.docker\.internal:35432#@${POSTGRES_ADDR}:${POSTGRES_PORT}#g" \
  -e "s#host=127\.0\.0\.1 #host=${POSTGRES_ADDR} #g" \
  -e "s#localhost:34317#${OTEL_ADDR}#g" \
  -e "s#127\.0\.0\.1:34317#${OTEL_ADDR}#g" \
  -e "s#175\.24\.130\.226:34317#${OTEL_ADDR}#g" \
  -e "s#host\.docker\.internal:34317#${OTEL_ADDR}#g" \
  "$dst"
}

show_config_hint() {
  local name="$1"
  local file="$2"
  log "config ready: ${name} => ${file}"
  grep -E '^(Name:|Host:|Port:|ListenOn:|Endpoint:|Path:|MetricsPath:|Key:|Mode:)' "$file" || true
}

api_pid=""
rpc_pid=""

stop_all() {
  set +e
  log "stopping children..."
  if [[ -n "$api_pid" ]] && kill -0 "$api_pid" 2>/dev/null; then
    kill "$api_pid" 2>/dev/null || true
  fi
  if [[ -n "$rpc_pid" ]] && kill -0 "$rpc_pid" 2>/dev/null; then
    kill "$rpc_pid" 2>/dev/null || true
  fi
  wait ${api_pid:-} ${rpc_pid:-} 2>/dev/null || true
}

trap 'log "received TERM/INT"; stop_all; exit 0' TERM INT

log "service=${SERVICE_NAME}"
log "api_enabled=${API_ENABLED} rpc_enabled=${RPC_ENABLED}"
log "API_WORKDIR=${API_WORKDIR}"
log "RPC_WORKDIR=${RPC_WORKDIR}"
log "API_BIN=${API_BIN}"
log "RPC_BIN=${RPC_BIN}"
log "ETCD_ADDR=${ETCD_ADDR}"
log "REDIS_ADDR=${REDIS_ADDR}"
log "POSTGRES_ADDR=${POSTGRES_ADDR}:${POSTGRES_PORT}"
log "KAFKA_ADDR=${KAFKA_ADDR}"
log "MINIO_ADDR=${MINIO_ADDR}"
log "OTEL_ADDR=${OTEL_ADDR}"

if [[ "$RPC_ENABLED" == "1" ]]; then
  rpc_config_tmp="/tmp/service-configs/${SERVICE_NAME}-rpc.yaml"
  log "patch rpc config: ${RPC_WORKDIR}/${RPC_CONFIG}"
  patch_config "$RPC_WORKDIR/$RPC_CONFIG" "$rpc_config_tmp"
  show_config_hint "rpc" "$rpc_config_tmp"
  (
    cd "$RPC_WORKDIR"
    log "starting rpc: ${RPC_BIN} -f ${rpc_config_tmp}"
    exec "$RPC_BIN" -f "$rpc_config_tmp"
  ) &
  rpc_pid="$!"
  log "rpc started pid=${rpc_pid}"
fi

if [[ "$API_ENABLED" == "1" ]]; then
  api_config_tmp="/tmp/service-configs/${SERVICE_NAME}-api.yaml"
  log "patch api config: ${API_WORKDIR}/${API_CONFIG}"
  patch_config "$API_WORKDIR/$API_CONFIG" "$api_config_tmp"
  show_config_hint "api" "$api_config_tmp"
  (
    cd "$API_WORKDIR"
    log "starting api: ${API_BIN} -f ${api_config_tmp}"
    exec "$API_BIN" -f "$api_config_tmp"
  ) &
  api_pid="$!"
  log "api started pid=${api_pid}"
fi

if [[ -z "$api_pid" && -z "$rpc_pid" ]]; then
  log "no process configured for service=${SERVICE_NAME}"
  exit 1
fi

while true; do
  if [[ -n "$rpc_pid" ]] && ! kill -0 "$rpc_pid" 2>/dev/null; then
    log "rpc exited pid=${rpc_pid}"
    wait "$rpc_pid" || true
    stop_all
    exit 1
  fi

  if [[ -n "$api_pid" ]] && ! kill -0 "$api_pid" 2>/dev/null; then
    log "api exited pid=${api_pid}"
    wait "$api_pid" || true
    stop_all
    exit 1
  fi

  sleep 1
done
