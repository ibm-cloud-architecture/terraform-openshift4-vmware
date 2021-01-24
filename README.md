# OpenShift 4.6 UPI Deployment with Static IPs

**Unfornately, the new capability of OpenShift 4.6 to pass Static IP's thru the ignition string don't currently work in the VCD environment because the ignition strings depend on VMWare vm_advanced_config parameters, which aren't available in VCD. A bugzilla has been opened ([Bugzilla ID 1913791](https://bugzilla.redhat.com/show_bug.cgi?id=1913791)) but its really a VCD issue. To get around this issue, the best approach is to come up with a scheme for DHCP reservations for the OpenShift servers based on MAC address. Today, this is done manually by going into the Edge Gateway Services definition and going into the DHCP Bindings section.  VCD doesn't allow terraform creation of the Edge Gateway DHCP Bindings so I am trying to figure out the best way to generate dhcpd.conf file to contain the DHCP Reservation and install a dhcpd server on the LB (alongside the DNS and HAProxy). I've already figured out how to get the dhcp server out there, I just need to generate the dhcpd.conf file. Its a little problematic in terraform so I may just use a shell script (if someone has the time to write one)**

![gateway](./media/edgegateway.png)

Deploy OpenShift 4.6 and later using static IP addresses for CoreOS nodes. The `ignition` module will inject code into the cluster that will automatically approve all node CSRs.  This runs only once at cluster creation.  You can delete the `ibm-post-deployment` namespace once your cluster is up and running.

**NOTE**: This requires OpenShift 4.6 or later to deploy, if you're looking for 4.5 or earlier, take a look at the `pre-4.6` [branch](https://github.com/ibm-cloud-architecture/terraform-openshift4-vmware/tree/pre-4.6)

**NOTE**: Requires terraform 0.13 or later.

## Architecture

OpenShift 4.6 User-Provided Infrastructure

![topology](./media/topology.png)

## Prereqs

1. [DNS](https://docs.openshift.com/container-platform/4.6/installing/installing_vsphere/installing-vsphere.html#installation-dns-user-infra_installing-vsphere) needs to be configured ahead of time
    - If you're using the helper vm for internal DNS, the only external DNS entries required are:
      - api.`cluster_id`.`base_domain`
      - *.apps.`cluster_id`.`base_domain`
    - Point both of those DNS A or CNAME records to either your LoadBalancers or the public IP address of the CoreOS LoadBalancer VM
2. [CoreOS OVA](http://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/) must be uploaded to a VCD Catalog as a template.

## Installation Process

```bash
git clone https://github.com/slipsibm/terraform-openshift4-vmware
cd terraform-openshift4-vmware
```

Update your `terraform.tfvars` with your environment values.  See `terraform.tfvars.example`

```bash
terraform init
terraform plan
terraform apply
```

## terraform variables

| Variable                     | Description                                                  | Type | Default |
| ---------------------------- | ------------------------------------------------------------ | ---- | ------- |
| vcd_url               | url for the VDC api                    | string | https://daldir01.vmware-solutions.cloud.ibm.com/api |
| vcd_user                     | VCD username                                             | string | - |
| vcd_password             | VCD password                                             | string | - |
| vcd_vdc                      | VCD VDC name          | string | - |
| cluster_id                   | VCD Cluster where OpenShift will be deployed             | string | - |
| vcd_org   |  VCD Org from VCD Console screen |  string |   |
| rhcos_template | Name of CoreOS OVA template from prereq #2 | string | - |
| lb_template | VCD Network for OpenShift nodes                   | string | - |
| vcd_catalog   | Name of VCD Catalog containing your templates  | string  |  Public Catalog |
| vm_network | VCD Network for OpenShift nodes                   | string | - ||   |   |   |   |
| loadbalancer_network       | VCD Network for Loadbalancer/DNS VM                      | string | -                              |
| vm_dns_addresses           | List of DNS servers to use for your OpenShift Nodes          | list   | 8.8.8.8, 8.8.4.4               |
| base_domain                | Base domain for your OpenShift Cluster                       | string | -                              |
| machine_cidr | CIDR for your CoreOS VMs in `subnet/mask` format.            | string | -                              |
| bootstrap_ip_address|IP Address for bootstrap node|string|-|
| bootstrap_mac_address|MAC Address for bootstrap node|string|-|
| control_plane_mac_addresses|List of mac addresses for your control plane nodes|list|-|
| control_plane_count          | Number of control plane VMs to create                        | string | 3                |
| control_plane_memory         | Memory, in MB, to allocate to control plane VMs              | string | 16384            |
| control_plane_num_cpus| Number of CPUs to allocate for control plane VMs             |string|4|
| control_disk  | size in MB   | string  |  - |
| compute_ip_addresses|List of IP addresses for your compute nodes|list|-|
| compute_mac_addresses|List of MAC addresses for your compute nodes|list|-|
| compute_count|Number of compute VMs to create|string|3|
| compute_memory|Memory, in MB, to allocate to compute VMs|string|8192|
| compute_num_cpus|Number of CPUs to allocate for compute VMs|string|3|
| compute_disk  | size in MB   | string  |  - |
| storage_ip_addresses|List of IP addresses for your storage nodes|list|`Empty`|
| storage_mac_addresses|List of MAC addresses for your storage nodes|list|`Empty`|
| storage_count|Number of storage VMs to create|string|0|
| storage_memory               | Memory, in MB to allocate to storage VMs                     | string | 65536            |
| storage_num_cpus             | Number of CPUs to allocate for storage VMs                   | string | 16               |
| storage_disk  | size in MB must be min of 2097152 to install OCS   | string  |  2097152 |
| lb_ip_address                | IP Address for LoadBalancer VM on same subnet as `machine_cidr` | string | -                |
| loadbalancer_lb_ip_address   | IP Address for LoadBalancer VM for secondary NIC on same subnet as `loadbalancer_lb_machine_cidr` | string | -                |
| loadbalancer_lb_machine_cidr | CIDR for your LoadBalancer CoreOS VMs in `subnet/mask` format | string | -                |
| openshift_pull_secret        | Path to your OpenShift [pull secret](https://cloud.redhat.com/openshift/install/vsphere/user-provisioned) | string | -                |
| openshift_cluster_cidr       | CIDR for pods in the OpenShift SDN                           | string | 10.128.0.0/14    |
| openshift_service_cidr       | CIDR for services in the OpenShift SDN                       | string | 172.30.0.0/16    |
| openshift_host_prefix        | Controls the number of pods to allocate to each node from the `openshift_cluster_cidr` CIDR. For example, 23 would allocate 2^(32-23) 512 pods to each node. | string | 23               |
| openshift_version            | Version of OpenShift to install. 4.6 or later.               | string | 4.6              |
| create_loadbalancer_vm | Create the LoadBalancer VM and use it as a DNS server for your cluster.  If set to `false` you must provide a valid pre-configured LoadBalancer for your `api` and `*.apps` endpoints and DNS Zone for your `cluster_id`.`base_domain`. | bool | false |

## Create Openshift Container Storage Cluster
 If you want to add OCS instead of NFS for storage provisioner, Instructions here -> [Openshift Container Storage - Bare Metal Path](https://access.redhat.com/documentation/en-us/red_hat_openshift_container_storage/4.6/html-single/deploying_openshift_container_storage_using_bare_metal_infrastructure/index#installing-openshift-container-storage-operator-using-the-operator-hub_rhocs)
