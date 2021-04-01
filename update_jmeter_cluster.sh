#!/usr/bin/env bash
# https://betterdev.blog/minimal-safe-bash-script-template/

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF

Usage: 

$(basename "${BASH_SOURCE[0]}") [-h] namespace

Update/apply the latest Kubernete configuration for the JMeter cluster in <namespace>.
Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info

EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --no-color) NO_COLOR=1 ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")

  # check required params and arguments
  [[ ${#args[@]} -lt 1 ]] && die "Missing namespace. Use -h for help."

  return 0
}

parse_params "$@"
setup_colors

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

echo

echo "Applying $nodes Jmeter slave replicas and service"

echo

kubectl apply -n $tenant -f $script_dir/jmeter_slaves_deploy.yaml

kubectl apply -n $tenant -f $script_dir/jmeter_slaves_svc.yaml

echo "Applying Jmeter Master"

kubectl apply -n $tenant -f $script_dir/jmeter_master_configmap.yaml

kubectl apply -n $tenant -f $script_dir/jmeter_master_deploy.yaml


echo "Applying Influxdb and the service"

kubectl apply -n $tenant -f $script_dir/jmeter_influxdb_configmap.yaml

kubectl apply -n $tenant -f $script_dir/jmeter_influxdb_deploy.yaml

kubectl apply -n $tenant -f $script_dir/jmeter_influxdb_svc.yaml

echo "Applying Grafana Deployment"

kubectl apply -n $tenant -f $script_dir/jmeter_grafana_deploy.yaml

kubectl apply -n $tenant -f $script_dir/jmeter_grafana_reporter.yaml

kubectl apply -n $tenant -f $script_dir/jmeter_grafana_svc.yaml
