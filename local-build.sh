#!/usr/bin/env bash

set -o nounset -o pipefail -o errexit

DO_CHECK=false
SERVICE=""

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    --check) DO_CHECK=true ;;
    --service=*) SERVICE="${arg#*=}" ;;
    *) echo "❌ Unknown argument: $arg" >&2; exit 1 ;;
  esac
done

### Detect docker or podman
cmd=docker
build_cmd="$cmd build --no-cache"
if command -v podman > /dev/null; then
  cmd=podman
  build_cmd="$cmd build --format docker --no-cache"
fi

### Shared environment for test runs
ENV_VARS=(
  -e MYSQL_ROOT_PASSWORD=foo
  -e MYSQL_USER=bar
  -e MYSQL_PASSWORD=secret
  -e MYSQL_DATABASE=db
  -e API_MONGO_USER=foo
  -e API_MONGO_PASSWORD=secret
  -e TEST=1
)

### Determine which services to build
ALL_SERVICES=(mysql solr mongo redis)
if [[ -n "$SERVICE" ]]; then
  SERVICES=("$SERVICE")
else
  SERVICES=("${ALL_SERVICES[@]}")
fi

### Build and optionally test each service
for service in "${SERVICES[@]}"; do
  version=$(grep '=' "$service/requirements.txt" |grep -v '#' | head -n 1 | cut -d = -f2)

  echo "🔧 Building freva-$service:$version ..."
  $build_cmd \
    --build-arg=SERVICE=$service \
    --build-arg=VERSION=$version \
    -t ghcr.io/freva-clint/freva-$service:latest \
    -t ghcr.io/freva-clint/freva-$service:$version .

  if $DO_CHECK; then
    echo "🧪 Testing freva-$service ..."
    $cmd run --rm "${ENV_VARS[@]}" \
      ghcr.io/freva-clint/freva-$service healthchecks
  fi
done

echo "✅ All builds completed successfully."
if $DO_CHECK; then
  echo "✅ All healthchecks passed."
fi
