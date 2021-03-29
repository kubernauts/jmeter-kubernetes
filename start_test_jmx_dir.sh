#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] 

To launch Jmeter tests directly from the current terminal without accessing the jmeter master pod.
It requires that you supply the directory containing to the jmx file, and all supporting files that associated with the test such as propeties and csv files.
The directory must contain ONE, and ONLY ONE, jmx file.
After execution, test script jmx file may be deleted from the pod itself but not locally.

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
EOF
# -f, --flag      Some flag description
# -p, --param     Some param description
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
  # default values of variables set from params
  # flag=0
  # param=''

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --no-color) NO_COLOR=1 ;;
    # -f | --flag) flag=1 ;; # example flag
    # -p | --param) # example named parameter
    #   param="${2-}"
    #   shift
    #   ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")

  # check required params and arguments
  # [[ -z "${param-}" ]] && die "Missing required parameter: param"
  [[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"

  return 0
}

parse_params "$@"
setup_colors

# script logic here

# msg "${RED}Read parameters:${NOFORMAT}"
# msg "- flag: ${flag}"
# msg "- param: ${param}"
# msg "- arguments: ${args[*]-}"



working_dir="`pwd`"

#Get namesapce variable
tenant=`awk '{print $NF}' "$script_dir/tenant_export"`

jmx="$1"
echo $tenant
echo $jmx


# [ -n "$jmx" ] || read -p 'Enter path to the jmx file ' jmx

# if [ ! -f "$jmx" ];
# then
#     echo "Test script file was not found in PATH"
#     echo "Kindly check and input the correct file path"
#     exit
# fi

# test_name="$(basename "$jmx")"

# echo $test_name

# #Get Master pod details

# master_pod=`kubectl get po -n $tenant | grep jmeter-master | awk '{print $1}'`

# kubectl cp "$jmx" -n $tenant "$master_pod:/$test_name"

# ## Echo Starting Jmeter load test

# kubectl exec -ti -n $tenant $master_pod -- /bin/bash /load_test "$test_name"
