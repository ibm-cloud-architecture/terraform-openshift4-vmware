#!/usr/bin/env bash
#
# Script to approve CSRs for nodes in an OCP 4.x cluster.
#
# INPUTS:
#   --node-count|--nodes   - (optional) the number of nodes for which CSRs need to be approved
#                            Defaults to 0 which means approve all CSRs
#   --wait-time            - (optional) how long to sleep (seconds) between each CSR check
#                            Defaults to 60
#   --wait-count           - (optional) how many times to wait
#                            Defaults to 10
#
# OUTPUTS:
#   - Trace output to stdout and logs/approve-csrs.log
#
# ASSUMPTIONS:
#   - Bash 4.3 or newer is being used.  Associative and name variables are used
#     in this script.
#   - OpenShift CLI (oc) is installed in $PWD
#   - A KUBECONFIG file is available in $PWD/auth/kubeconfig
#
# Sample invocations:
#   See usage() function below.
#

# Provide usage information here.
function usage {
  echo "Usage: approve-csrs.sh [options]"
  echo "  --nodes|--node-count POS_INT  - (optional) the number of nodes to be approved"
  echo "                                  Defaults to 0, which means approve all CSRs"
  echo "  --wait-time POS_INT           - (optional) the number of seconds for each wait between approval checks"
  echo "                                  Defaults to 60 seconds"
  echo "  --wait-count POS_INT          - (optional) the number of times to wait for wait-count seconds"
  echo "                                  Defaults to 10"
  echo "  --help|-h                     - emit this usage information"
  echo ""
  echo " Sample invocations:"
  echo " ./approve-csrs.sh"
  echo " ./approve-csrs.sh --nodes 9"
  echo " ./approve-csrs.sh --nodes 9 --wait-time 30 --wait-count 20"
  echo " When you provide a node count, the script finishes as soon as the expected number of CSRs have been approved."
}

source $(dirname $0)/common.sh

##### MAIN #####
SCRIPT=${0##*/}

check-prereqs

# Make sure there is a "logs" directory in the current directory
if [ ! -d "${PWD}/logs" ]; then
  mkdir ${PWD}/logs
  rc=$?
  if [ "$rc" != "0" ]; then
    # Not sure why this would ever happen, but...
    # Have to echo here since trace log is not set yet.
    echo "Creating ${PWD}/logs directory failed.  Exiting..."
    exit 1
  fi
fi

LOGFILE="${PWD}/logs/${SCRIPT%.*}.log"
if [ -f "$LOGFILE" ]; then
  roll_file "$LOGFILE"
fi

trace $SCRIPT $LINENO "main" "BEGIN $SCRIPT"

node_count=""
wait_time=""
wait_count=""

# process the input args
# For keyword-value arguments the arg gets the keyword and
# the case statement assigns the value to a script variable.
# If any "switch" args are added to the command line args,
# then it wouldn't need a shift after processing the switch
# keyword.  The script variable for a switch argument would
# be initialized to "false" or the empty string and if the
# switch is provided on the command line it would be assigned
# "true".
#
while (( $# > 0 )); do
  arg=$1
  case $arg in
    -h|-help|--help ) usage
    trace $SCRIPT $LINENO "main" "END $SCRIPT"
    exit 0
                  ;;

    --nodes|--node-count ) node_count=$2; shift
                  ;;

    --wait-time ) wait_time=$2; shift
                  ;;

    --wait-count ) wait_count=$2; shift
                  ;;

    * ) usage; trace $SCRIPT $LINENO "main" "Unknown option: $arg in command line."
        exit 2
                  ;;
  esac
  # shift to next key-value pair
  shift
done

if [ -z "$node_count" ]; then
  node_count=0
fi

if [ -z "$wait_time" ]; then
  wait_time=60
fi

if [ -z "$wait_count" ]; then
  wait_count=10
fi

if [ -e $PWD/oc ]; then
  export OC="./oc"
else
  test -e $(which oc) && {
    export OC=$(which oc)
  } || {
    trace $SCRIPT $LINENO "main" "ERROR: oc not found in current working directory or path."
    exit 3
  }
fi


if [ -e "$PWD/auth/kubeconfig" ]; then
  export KUBECONFIG=$PWD/auth/kubeconfig
else
  test -e $KUBECONFIG && {
    export KUBECONFIG
  } || {
    trace $SCRIPT $LINENO "main" "ERROR: kubeconfig file not found."
    echo "Get a copy of the cluster kubeconfig and put it here: $PWD/auth/kubeconfig"
    exit 4
  } 
fi

if [ $node_count -gt 0 ]; then
  trace $SCRIPT $LINENO "main" "INFO: Invoking: approve-csrs node_count=$node_count wait_time=$wait_time wait_count=$wait_count..."
  approve-csrs $node_count $wait_time $wait_count
else
  trace $SCRIPT $LINENO "main" "INFO: Invoking: approve-all-csrs wait_time=$wait_time wait_count=$wait_count..."
  approve-all-csrs $wait_time $wait_count
fi

trace $SCRIPT $LINENO "main" "END $SCRIPT"
