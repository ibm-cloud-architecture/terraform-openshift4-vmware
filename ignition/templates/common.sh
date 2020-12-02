################################################################################
# The trace() function has the following invocation form:
#  trace $file $LINENO $method "msg"
#  trace expects up to 2 "global" environment variables to be set:
#    $LOGFILE        - the full path to the log file associated with
#                      the script that is calling trace()
#    $CALLER_LOGFILE - the full path to the log file associated with the
#                      caller of the script. This env var may be empty
#                      in which case there is no caller log file.
#                      This additional log file is intended to support
#                      an aggregated log file.
#
function trace {
  local file=$1; shift
  local lineno=$1; shift
  local method=$1; shift

  ts=$(date +[%Y/%m/%d-%T])
  echo "$ts $file:$method($lineno) $*" | tee -a $LOGFILE $CALLER_LOGFILE
}

# The roll_file() function takes the following argument(s)
#   1. filePath - full path to the file to be "rolled"
#
# It is assumed the caller has write permission in the directory
# where the file is located.
# The roll_file() function adds a time stamp to the file name
# immediately before the file extension, then moves the given
# file to the new file with the time stamp in its name.
#
# The roll_file() function is intended to be used in scenarios such
# as logging, where it is desirable to retain previous log files and
# a new log file with the same name is to be created.
#
function roll_file {
  local filePath="$1"
  local ts=$(date "+%Y-%m-%d_%H_%M_%s")
  # Extract the directory part of the path
  dir=${filePath%/*}
  # Extract the file name part of the path
  fileName=${filePath##*/}
  # Strip the extension from the file name
  name=${fileName%.*}
  # Extract the file name extension
  ext=${fileName##*.}
  newFilePath="${dir}/${name}_${ts}.${ext}"
  mv "$filePath" "$newFilePath"
}


# The general-prereqs() function checks the bash version, jq and other utilities
function general-prereqs {
  local bash_major_version=${BASH_VERSION%%.*}
  local the_rest=${BASH_VERSION#*.}
  local bash_minor_version=${the_rest%%.*}

  [[ $bash_major_version -gt 4 || ( $bash_major_version -eq 4  && $bash_minor_version -ge 3 ) ]] || {
    echo "The version of bash, ${BASH_VERSION}, does not support associative arrays and by-name parameters."
    echo "  Upgrade bash to the latest version."
    echo "  To install the latest bash on MacOS, see https://itnext.io/upgrading-bash-on-macos-7138bd1066ba"
    exit 1
  }
}


function check-prereqs {
  general-prereqs
}

function get-compute-node-count {
  oc get nodes --selector=node-role.kubernetes.io/worker | awk 'NR>1' | wc -l | sed -e 's/^[ \t]*//'
}

# The approve-node-bootstrapper-csrs() approves the first round of CSRs that appear
# for new nodes in an OCP cluster.  All nodes need CSRs approved when a cluster is
# first created.  When nodes are added to the cluster, the CSRs need to be approved.
# For each new node, a node-bootstrapper CSR needs to be approved.
function approve-node-bootstrapper-csrs() {
  local node_count=$1
  local wait_time=${2:-60}
  local wait_count=${3:-5}
  local csrs_approved=0 wait=0 pending_csrs
  local file="common.sh" method="approve-node-bootstrapper-csrs"

  while [ $csrs_approved -lt $node_count ] && [ $wait -lt $wait_count ]; do
    pending_csrs=$($OC get csr | grep "Pending" | grep "node-bootstrapper" | wc -l)
    if [ $pending_csrs -eq 0 ]; then
      trace $file $LINENO $method "INFO: Waiting for pending CSRs."
    else
      pending_csrs=$($OC get csr | grep "Pending" | grep "node-bootstrapper" | awk '{print $1}' | tr '\n' ' ')
      for csr in $pending_csrs; do
        trace $file $LINENO $method "Approving CSR $csr..."
        $OC adm certificate approve $csr | tee -a $LOGFILE
        csrs_approved=$(( csrs_approved + 1 ))
      done
    fi
    sleep $wait_time
    wait=$(( wait + 1 ))
  done

  if [ $csrs_approved -eq $node_count ]; then
    trace $file $LINENO $method "INFO: Approved $csrs_approved/$node_count node-bootstrapper CSRs."
  else
    trace $file $LINENO $method "WARNING: Timed out waiting for pending node-bootstrapper CSRS. Approved $csrs_approved/$node_count node-bootstrapper CSRs"
  fi
}


# The approve-csrs() function is used to approve all the CSRs associated
# with new nodes in an OCP cluster. All nodes need CSRs approved when a cluster is
# first created.  When nodes are added to the cluster, the CSRs need to be approved.
# If the number of nodes for which CSRs need to be approved is unknown, use approve-all-csrs()
# defined below.
function approve-csrs() {
  local node_count=$1
  local wait_time=${2:-60}
  local wait_count=${3:-5}
  declare file="common.sh" method="approve-csrs"

  trace $file $LINENO $method "INFO: Approving CSRs for ${node_count} nodes..."
  approve-node-bootstrapper-csrs $node_count $wait_time $wait_count

  local csrs_approved=0 wait=0 csr_node_name="" pending_csrs
  while [ $csrs_approved -lt $node_count ] && [ $wait -lt $wait_count ]; do
    pending_csrs=$($OC get csr | tail -n +2 | grep "Pending" | wc -l)
    if [ $pending_csrs -eq 0 ]; then
      trace $file $LINENO $method "INFO: Waiting for pending CSRs."
    else
      pending_csrs=$($OC get csr | grep "Pending" | awk '{print $1}' | tr '\n' ' ')
      for csr in $pending_csrs; do
        csr_node_name=$($OC get csr | grep $csr | awk '{print $3}')
        csr_node_name=${csr_node_name##*:}  # get just the fqdn part of the CSR requestor
        trace $file $LINENO $method "INFO: Approving CSR $csr for node $csr_node_name..."
        $OC adm certificate approve $csr | tee -a $LOGFILE
        csrs_approved=$(( csrs_approved + 1 ))
      done
    fi
    sleep $wait_time
    wait=$(( wait + 1 ))
  done
}

# The approve-all-csrs() function is called when the number of CSRs to approve is unknown.
# This function is in support of a cluster deployment process where the the number of nodes
# in the new cluster has not been provided.  The script sits in a loop for the given number
# of wait_counts, sleeping each time for the given wait_time seconds before checking again
# to see if any CSRs are pending.
# If the number of nodes for which CSRs need to be approved is known, use approve-csrs()
# defined above. It's more deterministic and exits as soon as its work is complete.
# The approve-all-csrs() function completes after wait_time*wait_count seconds.
function approve-all-csrs() {
  local wait_time=${1:-30}
  local wait_count=${2:-20}
  declare file="common.sh" method="approve-all-csrs"

  trace $file $LINENO $method "INFO: Approving all CSRs..."

  local csrs_approved=0 wait=0 csr_node_name="" pending_csrs
  while [ $wait -lt $wait_count ]; do
    pending_csrs=$($OC get csr | tail -n +2 | grep "Pending" | wc -l)
    if [ $pending_csrs -eq 0 ]; then
      trace $file $LINENO $method "INFO: Waiting for pending CSRs."
    else
      pending_csrs=$($OC get csr | grep "Pending" | awk '{print $1}' | tr '\n' ' ')
      for csr in $pending_csrs; do
        csr_node_name=$($OC get csr | grep $csr | awk '{print $3}')
        csr_node_name=${csr_node_name##*:}  # get just the fqdn part of the CSR requestor
        trace $file $LINENO $method "INFO: Approving CSR $csr for node $csr_node_name..."
        $OC adm certificate approve $csr | tee -a $LOGFILE
        csrs_approved=$(( csrs_approved + 1 ))
      done
    fi
    sleep $wait_time
    wait=$(( wait + 1 ))
  done

  trace $file $LINENO $method "INFO: Approved ${csrs_approved} CSRs."
}
