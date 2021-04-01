#!/usr/bin/env bash
# https://betterdev.blog/minimal-safe-bash-script-template/

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF

Usage: 

$(basename "${BASH_SOURCE[0]}") [-h] test_plan_dir jmx_file properties_file test_report_name

test_plan_dir: The test plan directory.
jmx_file: The jmeter test file name. Must be at the surface level in the test plan directory.
properties_file: The properties file name to be used with the jmx. Must be at the surface level in the test plan directory.
test_report_name: Name for the generated JMeter test report and output log. Must be at the surface level in the test plan directory.

To launch Jmeter tests directly from the current terminal without accessing the jmeter-master pod.
It requires that you supply the test plan directory (test_plan_dir), which contains jmx_file and properties_file at the surface level.
The directory may contain additional supporting files, such as propeties and csv files.
The entire directory will be copied into the jmeter_master pod, and only the jmx file specified as properties_file at the surface will be executed.
After execution, the jmeter test log file (jtl) and a HTML report will be pulled from the jmeter-master pod and packaged into a zip file using test_report_name.

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
  [[ ${#args[@]} -lt 4 ]] && die "Arguments incomplete. Use -h for help."

  return 0
}

parse_params "$@"
setup_colors

# Get namesapce variable stored in tenant_export.
tenant=`awk '{print $NF}' "$script_dir/tenant_export"`

POD_WORK_DIR="/"
test_plan_dir="$1"
jmx_file=`basename $2`
jmx_file="${jmx_file%.*}"
properties_file=`basename $3`
properties_file="${properties_file%.*}"
test_report_name="$4"

# Assert test_plan_dir exsists on the local machine, and the jmx_file and properties_file are located at its surface level. 
if [ ! -d "$test_plan_dir" ]
then
  die "Directory $test_plan_dir does not exist! Use -h for help."
else
  if [ ! -f "$test_plan_dir/$jmx_file.jmx" ]
  then
    die "'$jmx_file.jmx' does not exist at the surface level of directory '$test_plan_dir'.  Use './`basename ${BASH_SOURCE[0]}` -h' for help"
  elif [ ! -f "$test_plan_dir/$properties_file.properties" ]
  then
    die "'$properties_file.properties' does not exist at the surface level of directory $test_plan_dir.  Use './`basename ${BASH_SOURCE[0]}` -h' for help"
  fi
fi

# Get master pod details
master_pod=`kubectl -n $tenant get po | grep jmeter-master | awk '{print $1}'`

msg "Checking if $test_report_name already exists in the jmeter-master pod..."
report_jtl_or_dir_count=`kubectl -n $tenant exec -ti $master_pod -- find $POD_WORK_DIR/ -maxdepth 1 \
  \( -type d -name ${test_report_name} -or -name ${test_report_name}.jtl \) | wc -l | xargs`

if [ $((report_jtl_or_dir_count)) -lt 0 ]
then
  now=`date +"%H%M%S_%Y%b%d"`
  new_test_report_name="${test_report_name}_${now}"
  msg "${test_report_name} already esists in the jmeter master pod. Renaming it with current date as ${new_test_report_name}"
  test_report_name=$new_test_report_name
fi

msg "Pushing test files into jmeter-master pod $master_pod:$POD_WORK_DIR/$test_plan_dir ..."
kubectl -n $tenant exec -ti $master_pod -- rm -rf $POD_WORK_DIR/$test_plan_dir
kubectl -n $tenant cp $test_plan_dir $master_pod:$POD_WORK_DIR/$test_plan_dir

# Get slave pods details
slave_pods=(`kubectl get po -n $tenant | grep jmeter-slave | awk '{print $1}'`)
for slave_pod in ${slave_pods[@]}
  do
    echo 'Do Nothing'
    # msg "Pushing test files into jmeter-slave pod $slave_pod:$POD_WORK_DIR/$test_plan_dir"
    kubectl -n $tenant exec -ti $slave_pod  -- rm -rf $POD_WORK_DIR/$test_plan_dir
    # kubectl -n $tenant cp $test_plan_dir $slave_pod:$POD_WORK_DIR/$test_plan_dir
done

msg "Starting the JMeter test..."
kubectl exec -ti -n $tenant $master_pod -- /bin/bash /load_test $POD_WORK_DIR $test_plan_dir $jmx_file.jmx $properties_file.properties $test_report_name.jtl

msg "Generating the JMeter HTML report..."
kubectl exec -ti -n $tenant $master_pod -- /bin/bash /generate_report $POD_WORK_DIR/$test_report_name.jtl $POD_WORK_DIR/$test_report_name

msg "Pulling the test report and log from the master pod..."
kubectl -n $tenant cp $master_pod:$POD_WORK_DIR/$test_report_name $test_report_name
kubectl -n $tenant cp $master_pod:$POD_WORK_DIR/$test_report_name.jtl $test_report_name/$test_report_name.jtl

msg "Packing the test report and log file into ${test_report_name}.zip..."
zip -qr $test_report_name.zip $test_report_name
