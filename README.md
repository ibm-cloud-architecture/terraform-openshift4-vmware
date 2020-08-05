# terraform-openshift4-vmware

Deploy OpenShift 4.3 and later using static IP addresses for master and worker nodes.  Will create a helper node with a webserver to serve ignition files, haproxy for loadbalancing, and DNS for internal cluster name resolution.  It will upload the OpenShift Bare Metal BIOS file and ignition files to the websever root, and will create a bootable ISO for each node with static IP configuration and ignition parameters already set.

## Prereqs

1. [DNS](https://docs.openshift.com/container-platform/4.3/installing/installing_vsphere/installing-vsphere.html#installation-dns-user-infra_installing-vsphere) needs to be configured ahead of time
    - If you're using the helper vm for internal DNS, the only external DNS entries required are:
      - api.cluster_id.domain.com
      - *.apps.cluster_id.domain.com
    - Point both of those DNS A or CNAME records to the public IP address of the helper vm.

## Installation Process

```bash
$ git clone https://github.com/ncolon/terraform-openshift4-vmware
$ cd terraform-openshift4-vmware
```

Update your `terraform.tfvars` with your environment values.  See `terraform.tfvars.example`


```bash
$ terraform init
$ terraform plan
$ terraform apply
```

## terraform variables

| Variable                     | Description                                                  | Type | Default |
| ---------------------------- | ------------------------------------------------------------ | ---- | ------- |
| vsphere_server               | FQDN or IP Address of your vSphere Server                    | string | - |
| vsphere_username             | vSphere username                                             | string | - |
| vsphere_password             | vSphere password                                             | string | - |
| vsphere_allow_insecure       | Allow vSphere self-signed certs                              | string | 1 |
| vsphere_datacenter           | vSphere Datacenter where OpenShift will be deployed          | string | - |
| vsphere_cluster              | vSphere Cluster where OpenShift will be deployed             | string | - |
| vsphere_image_datastore      | vSphere Datastore where bootable ISOS will be stored         | string | - |
| vsphere_image_datastore_path | vSphere Datastore path where bootable isos will be stored    | string | - |
| vsphere_node_datastore       | vSphere Datastore for OpenShift nodes                        | string | - |
| vsphere_private_network      | vSphere private Network for OpenShift nodes                  | string | - |
| vsphere_public_network       | vSphere public Network for OpenShift nodes                   | string | - |
| vsphere_folder               | vSphere Folder where VMs will be deployed into               | string | - |
| vsphere_resource_pool        | vSphere Resource Pool where VMs will be deployed into        | string | - |
| preexisting_resource_pool    | Indicates whether vSphere Resource Pool already exists       | bool   | false |
| binaries                     | map with URLs for openshift components                       | map    | See `terraform.tfvars.example` |
| openshift_base_domain        | Base domain for your OpenShift Cluster                       | string | - |
| openshift_cluster_id         | Name of your OpenShift cluster.  Cluster will be reachable at `api.$openshift_cluster_id.$openshift_base_domain`. | string | - |
| openshift_pull_secret        | Path to your OpenShift pull secret.  Download from https://cloud.redhat.com/openshift/install/vsphere/user-provisioned | string | - |
| openshift_cluster_cidr       | The IP address pools for pods                                | string | 10.128.0.0/14 |
| openshift_service_cidr       | CIDR for services in the OpenShift SDN                       | string | 172.30.0.0/16 |
| openshift_host_prefix        | The prefix size to allocate to each node from the CIDR. For example, 24 would allocate 2^8=256 adresses to each node. | string | 23 |
| private_network_gateway      | Network Gateway for OpenShift Nodes                          | string | - |
| private_network_netmask      | Network Mask for OpenShift Nodes in numerical form           | string | - |
| public_network_gateway       | Network Gateway for OpenShift Nodes                          | string | - |
| public_network_netmask       | Network Mask for OpenShift Nodes in numerical form           | string | - |
| public_network_nameservers   | Nameservers for OpenShift Nodes                              | list | |
| coreos_network_device        | Device Interface Name for CoreOS Nodes                       | string | ens192 |
| helper                       | Map with cpu, memory, disk (etc.) configuration for helper node | map  | See `terraform.tfvars.example` |
| helper_public_ip             | Public IP address of Helper VM                               | string | - |
| herlper_private_ip           | Private IP addrress of Helper VM                             | string | - |
| bootstrap                    | Map with cpu, memory, disk (etc.) configuration for bootstrap node | map  | See `terraform.tfvars.example` |
| bootstrap_hostname           | Hostname of bootstrap server | string | - |
| bootstrap_ip                 | IP Address of bootstrap serevr | string | - |
| master                       | Map with cpu, memory, disk (etc.) configuration for Master Nodes | map  | See `terraform.tfvars.example` |
| master_hostnames             | Hostnames of Control Plane Nodes | list | - |
| master_ips                   | IP Addresses of Control Plane Nodes | list | - |
| worker                       | Map with cpu, memory, disk (etc.) configuration for Worker Nodes | map  | See `terraform.tfvars.example` |
| worker_hostnames             | Hostnames of Worker Nodes | list | - |
| worker_ips                   | IP Addresses of Worker Nodes | list | - |
| storage                      | Map with cpu, memory, disk (etc.) configuration for Storage Node | map  | See `terraform.tfvars.example` |
| storage_hostnames            | Hostnames of Storage Nodes | list | - |
| storage_ips                  | IP Addresses of Storage Nodes | list | - |
| use_helper_for_node_dns      | Use the helper VM as DNS for your cluster | bool | true |
