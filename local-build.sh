#!/usr/bin/env bash

set -o nounset -o pipefail -o errexit

### Parse optional flags
DO_CHECK=false
if [[ "${1:-}" == "--check" ]]; then
    DO_CHECK=true
fi

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

### Build and optionally test each service
for service in mysql solr mongo redis; do
    version=$(head -n 1 "$service/requirements.txt" | cut -d = -f2)

    echo "🔧 Building freva-$service:$version ..."
    $build_cmd \
        --build-arg=SERVICE=$service \
        --build-arg=VERSION=$version \
        -t ghcr.io/freva-clint/freva-$service:latest \
        -t ghcr.io/freva-clint/freva-$service:$version .

    if $DO_CHECK; then
        echo "🧪 Testing freva-$service ..."
        $cmd run --name $service --rm -it "${ENV_VARS[@]}" \
            ghcr.io/freva-clint/freva-$service healthchecks
    fi
done

echo "✅ All builds completed successfully."
if $DO_CHECK; then
    echo "✅ All healthchecks passed."
fi
