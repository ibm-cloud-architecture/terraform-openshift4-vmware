// ID identifying the cluster to create. Use your username so that resources created can be tracked back to you.
cluster_id = "tfupi48"

// Base domain from which the cluster domain is a subdomain.
base_domain = "benoibm.com"

// Name of the vSphere server. The dev cluster is on "vcsa.vmware.devcluster.openshift.com".
vsphere_server = "cdavcenter.cda.internal"

// User on the vSphere server.
vsphere_user = "administrator@cda.internal"

// Password of the user on the vSphere server.
vsphere_password = "ICPassw0rd#"

// Name of the vSphere cluster. The dev cluster is "devel".
vsphere_cluster = "ocp"

// Name of the vSphere data center. The dev cluster is "dc1".
vsphere_datacenter = "Datacenter"

// Name of the vSphere data store to use for the VMs. The dev cluster uses "nvme-ds1".
vsphere_datastore = "cdanfs"

// Name of the RHCOS VM template to clone to create VMs for the cluster
vm_template = "coreos-4_8_14"

// Name of the VM Network for your cluster nodes
vm_network = "VM Network"

// Name of the VM Network for loadbalancer NIC in loadbalancer.
// loadbalancer_network = "vDPortGroup"

// The machine_cidr where IP addresses will be assigned for cluster nodes.
// Additionally, IPAM will assign IPs based on the network ID. 
machine_cidr = "192.168.10.0/24"

// The number of control plane VMs to create. Default is 3.
control_plane_count = 3

// The number of compute VMs to create. Default is 3.
compute_count = 2

// Set bootstrap_ip, control_plane_ip, and compute_ip if you want to use static
// IPs reserved someone else, rather than the IPAM server.

// The IP address to assign to the bootstrap VM.
bootstrap_ip_address = "192.168.10.20"

// The IP addresses to assign to the control plane VMs. The length of this list
// must match the value of control_plane_count.
control_plane_ip_addresses = ["192.168.10.21", "192.168.10.22", "192.168.10.23"]

// The IP addresses to assign to the compute VMs. The length of this list must
// match the value of compute_count.
compute_ip_addresses = ["192.168.10.24", "192.168.10.25"]

// The IP addresses of your DNS servers for your OpenShift nodes
vm_dns_addresses = ["192.168.10.2"]

// The IP address of the default gateway.  If not set, it will use the frist host of the machine_cidr range.
vm_gateway = "192.168.10.1"

// Path to your OpenShift Pull Secret
openshift_pull_secret = ""

// Set to true (default) so that OpenShift self-hosts its own LoadBalancers (similar to IPI deployments)
// If set to false, you must bring your own LoadBalancers and point the api enpoint to masters and apps endpoint to workers
create_openshift_vips = false

// If create_openshift_vips is set to true, you must provide the IP addresses that will be used for the api and *.apps endpoints
// These IP addresses MUST be on the same CIDR range as machine_cidr
openshift_api_virtualip = "192.168.100.201"
openshift_ingress_virtualip = "192.168.100.200"

// The number of storage VMs to create. Default is 0.  Set to 0 or 3
// storage_count = 3


// The IP addresses to assign to the storage VMs. The length of this list must
// match the value of storage_count.
//storage_ip_addresses = ["192.168.100.87", "192.168.100.88", "192.168.100.89"]

// Set MTU for worker VMs
// openshift_worker_mtu = 9000

// Set NTP server
// openshift_ntp_server = vistime.rtp.raleigh.ibm.com

// AirGapped Configuration
// Set enabled to true to configure your cluster for airgap install
// set repository to the hostname:port of your image registry
// NOTE:
//  The registry has to be running on an SSL/TLS secured port.
//  If the registry certificate uses a certificate signed by a a certificate authority
//   which RHCOS does not trust by default copy the certificate authority certificate
//   locally and update the openshift_additional_trust_bundle variable
// https://docs.openshift.com/container-platform/4.7/installing/installing_vsphere/installing-restricted-networks-installer-provisioned-vsphere.html#installation-creating-image-restricted_installing-restricted-networks-installer-provisioned-vsphere
// https://github.com/openshift/installer/blob/master/docs/user/customization.md#image-content-sources
// airgapped = {
//   enabled    = true
//   repository = "myrepository.example.com:8443"
// }

// Proxy Configuration
// Set enabled to true to configure your cluster-wide proxy at install time
// https://github.com/openshift/installer/blob/master/docs/user/customization.md#proxy
// proxy_config = {
//   enabled    = true
//   httpProxy  = "http://user:pass@proxy:port"
//   httpsProxy = "http://user:pass@proxy:port"
//   noProxy    = "ip1, ip2, ip3, .example.com, cidr/mask"
// }
// NOTE:
//  If the proxy uses a customCA to do traffic inspection,
//  (also known as man-in-the-middle proxy)
//  copy the customCA certificate locally and update the
//  openshift_additional_trust_bundle variable

// Custom CA certificate
// NOTE:
//   If any component in your cluster will communicate to services
//   secured by SSL/TLS certificates signed by a certificate authority
//   which RHCOS does not trust by default copy the certificate authority certificate
//   locally and update this variable.
//
//   The certificate MUST have the CA:TRUE basicContstain extension set.
// https://github.com/openshift/installer/blob/master/docs/user/customization.md#additional-trust-bundle
// openshift_additional_trust_bundle = "/path/to/customCA.crt"

