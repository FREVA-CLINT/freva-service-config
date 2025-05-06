#!/usr/bin/env bash
set -u -o nounset -o pipefail -o errexit

TEMP_DIR=$(mktemp -d)
PKG_NAME=freva-rest-server
PREFIX=${CONDA_PREFIX:-${MAMBA_ROOT_PREFix:-}}
SERVICES=(mongo mysql solr redis nginx)
SUFFIXES=(suffix in txt xml sql j2 html gif types)

print_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Start the micro services of the Freva RestAPI.

Options:
  -p, --prefix <name>    Installation Prefix, default: ${PREFIX}
  -h, --help             Show this help message and exit
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--prefix)
      export PREFIX="$2"
      shift 2
      ;;
    --prefix=*)
      export PREFIX="${1#*=}"
      shift
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      echo "❌ Unknown argument: \$1" >&2
      print_help
      exit 1
      ;;
  esac
done

if [ -z "${PREFIX}" ];then
    echo echo "❌ PREFIX must be set via -p or \$CONDA_PREFIX env var" >&2
    exit 1
fi

# Define an exit function
exit_func(){
    rm -rf $TEMP_DIR
    exit $1
}

check_for_git_reop(){
    for service in ${SERVICES[@]};do
        if [ ! -f $service/requirements.txt ];then
            git clone --recursive -b add-conda-recipe https://github.com/FREVA-CLINT/freva-service-config.git $TEMP_DIR
            cd $TEMP_DIR
            break
        fi
    done
}

# Trap exit signals to ensure cleanup is called
trap 'exit_func 1' SIGINT SIGTERM ERR


# Setup additional configuration
mkdir -p $PREFIX/etc/profile.d $PREFIX/libexec/$PKG_NAME
cat <<EOF > $PREFIX/etc/profile.d/freva-rest-server.sh
    #!/usr/bin/env bash
set -u

: "\${SERVICE:?SERVICE variable must be set before sourcing this script}"

export DATA_DIR=\${API_DATA_DIR:-$PREFIX/var/$PKG_NAME/\$SERVICE}
export LOG_DIR=\${API_LOG_DIR:-$PREFIX/var/log/$PKG_NAME/\$SERVICE}
export CONFIG_DIR=\${API_CONFIG_DIR:-$PREFIX/share/$PKG_NAME/\$SERVICE}
export USER=\$(whoami)

mkdir -p \$DATA_DIR \$LOG_DIR \$CONFIG_DIR || true
EOF
this_dir=$(pwd)
check_for_git_reop
for service in "${SERVICES[@]}";do
    mkdir -p $PREFIX/var/$PKG_NAME/$service
    mkdir -p $PREFIX/var/log/$PKG_NAME/$service
    mkdir -p $PREFIX/share/$PKG_NAME/$service/
    cp $service/init-$service $PREFIX/libexec/$PKG_NAME/
    for suffix in ${SUFFIXES[@]};do
        cp $service/*.$suffix $PREFIX/share/$PKG_NAME/$service/ 2> /dev/null || true
    done
    rm -f $PREFIX/share/$PKG_NAME/$service/requirements.txt
    cp docker-scripts/healthchecks.sh $PREFIX/libexec/$PKG_NAME/
    chmod +x $PREFIX/libexec/$PKG_NAME/*
done

cat <<EOI > $PREFIX/bin/start-freva-service
#!/usr/bin/env bash
# Start services for the freva-rest-api
#
set -u -o nounset -o pipefail -o errexit
supported_services=(${SERVICES[@]})

export SERVICE=\${SERVICE:-}
print_help() {
  cat <<EOF
Usage: $(basename "\$0") [OPTIONS]

Start the micro services of the Freva RestAPI.

Options:
  -s, --service <name>   Name of the service (\${supported_services[@]})
  -h, --help             Show this help message and exit
EOF
}

while [[ \$# -gt 0 ]]; do
  case "\$1" in
    -s|--service)
      export SERVICE="\$2"
      shift 2
      ;;
    --service=*)
      export SERVICE="\${1#*=}"
      shift
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    "\${supported_services[@]}")
      export SERVICE=\$1
      shift
      ;;
    *)
      echo "❌ Unknown argument: \$1" >&2
      print_help
      exit 1
      ;;
  esac
done

# Start the selected service
if [ -z "\$SERVICE" ];then
    echo "❌ No service specified: \$SERVICE" >&2
    print_help
    exit 1
elif [[ ! " \${supported_services[*]} " =~ " \${SERVICE} " ]];then
    echo "❌ Unsupported service: \$SERVICE" >&2
    echo "Supported services are: \${supported_services[*]}" >&2
    exit 1
fi

export CONDA_PREFIX=$PREFIX
export PATH=$PREFIX/bin:$PATH
SERVICE_SCRIPT=$PREFIX/libexec/$PKG_NAME/init-\$SERVICE
source $PREFIX/etc/profile.d/freva-rest-server.sh
trap "rm -rf /tmp/\$SERVICE || true" EXIT
exec \$SERVICE_SCRIPT
EOI
chmod +x $PREFIX/bin/start-freva-service
exit_func 0
