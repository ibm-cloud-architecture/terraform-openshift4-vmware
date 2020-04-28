
export KUBECONFIG=${HOME}/installer/auth/kubeconfig
cat <<EOF | oc create -f -
apiVersion: v1
kind: Namespace
metadata:
  labels:
    openshift.io/cluster-monitoring: "true"
  name: openshift-storage
spec: {}
EOF

cat <<EOF | oc create -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  annotations:
    olm.providedAPIs: BackingStore.v1alpha1.noobaa.io,BucketClass.v1alpha1.noobaa.io,CephBlockPool.v1.ceph.rook.io,CephClient.v1.ceph.rook.io,CephCluster.v1.ceph.rook.io,CephNFS.v1.ceph.rook.io,CephObjectStore.v1.ceph.rook.io,CephObjectStoreUser.v1.ceph.rook.io,NooBaa.v1alpha1.noobaa.io,OCSInitialization.v1.ocs.openshift.io,ObjectBucket.v1alpha1.objectbucket.io,ObjectBucketClaim.v1alpha1.objectbucket.io,StorageCluster.v1.ocs.openshift.io,StorageClusterInitialization.v1.ocs.openshift.io
  generateName: openshift-storage-
  namespace: openshift-storage
spec:
  targetNamespaces:
  - openshift-storage
EOF

OCS_VERSION=$(oc get packagemanifests -n openshift-marketplace ocs-operator -o yaml|grep version|tail -1|awk '{print $2}')
OCS_CHANNEL=$(oc get packagemanifests -n openshift-marketplace ocs-operator -o yaml|grep name|grep stable|tail -1|awk '{print $2}')
cat <<EOF | oc create -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ocs-operator
  namespace: openshift-storage
spec:
  channel: ${OCS_CHANNEL}
  installPlanApproval: Automatic
  name: ocs-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: ocs-operator.v${OCS_VERSION}
EOF

while ! oc api-resources|grep StorageCluster$ > /dev/null;do
  echo "Waiting for StorageCluster CRD"
  sleep 10
done

cat <<EOF | oc create -f -
apiVersion: ocs.openshift.io/v1
kind: StorageCluster
metadata:
  name: ocs-storagecluster
  namespace: openshift-storage
spec:
  manageNodes: false
  storageDeviceSets:
    - count: 1
      dataPVCTemplate:
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 512Gi
          storageClassName: null
          volumeMode: Block
      name: ocs-deviceset
      placement: {}
      portable: true
      replica: 3
      resources: {}
EOF
cat <<EOF | oc create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: image-registry-storage
  namespace: openshift-image-registry
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 100Gi
  storageClassName: ocs-storagecluster-cephfs
EOF
oc patch config cluster --type merge --patch '{"spec": {"managementState": "Managed", "replicas": 2, "storage": {"pvc": {"claim": ""}}}}'
