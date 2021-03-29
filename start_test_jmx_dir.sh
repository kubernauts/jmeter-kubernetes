#!/usr/bin/env bash
# https://betterdev.blog/minimal-safe-bash-script-template/

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] jmx_dir

To launch Jmeter tests directly from the current terminal without accessing the jmeter master pod.
It requires that you supply the test plan directory (jmx_dir), which contains ONLY ONE jmx file at the surface level.
The directory may contain additional supporting files, such as propeties and csv files.
The entire directory will be copied into the jmeter_master pod, and the jmx file at the surface will be executed.
After execution, test script jmx file may be deleted from the master pod but not locally.

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
  [[ ${#args[@]} -eq 0 ]] && die "Missing jmx_dir, directory containing the jmx test plan."

  return 0
}

parse_params "$@"
setup_colors

# Get namesapce variable stored in tenant_export.
tenant=`awk '{print $NF}' "$script_dir/tenant_export"`
jmx_dir="$1"

# Assert there is only one jmx file at the surface level. 
if [ ! -d "$jmx_dir" ]
then
  msg "Directory $jmx_dir does not exist!"
  msg "Kindly check and input the correct directory."
  exit
else
  jmx_num=`find $jmx_dir -maxdepth 1 -name "*.jmx" | wc -l | xargs`
  if [ $((jmx_num)) -eq 0 ]
  then
    msg "Directory $jmx_dir does not contain any jmx file at the surface level."
    exit
  elif [ $((jmx_num)) -gt 1 ]
  then
    msg "Directory $jmx_dir has multiple jmx files at the surface level. Only one is allowed."
    exit
  fi
fi

# Get FQN of the jmx file
jmx_name=`find $jmx_dir -maxdepth 1 -name "*.jmx"`

# Get Master pod details
master_pod=`kubectl get po -n $tenant | grep jmeter-master | awk '{print $1}'`

msg "Coping test files into jmeter-master pod $master_pod:/tmp/$jmx_dir ..."
kubectl exec -ti -n $tenant $master_pod  -- rm -rf /tmp/$jmx_dir
kubectl cp $jmx_dir -n $tenant $master_pod:/tmp/$jmx_dir

msg "Starting JMeter load test..."
kubectl exec -ti -n $tenant $master_pod -- /bin/bash /load_test /tmp/$jmx_name