# OpenShift 4.6 UPI Deployment with Static IPs

Deploy OpenShift 4.6 and later using static IP addresses for CoreOS nodes. The `ignition` module will inject code into the cluster that will automatically approve all node CSRs.  This runs only once at cluster creation.  You can delete the `ibm-post-deployment` namespace once your cluster is up and running.

**NOTE**: This requires OpenShift 4.6 or later to deploy, if you're looking for 4.5 or earlier, take a look at the `pre-4.6` branch

**NOTE**: Requires terraform 0.13 or later.



## Architecture

OpenShift 4.6 User-Provided Infrastructure



![](./media/topology.png	)

## Prereqs

1. [DNS](https://docs.openshift.com/container-platform/4.3/installing/installing_vsphere/installing-vsphere.html#installation-dns-user-infra_installing-vsphere) needs to be configured ahead of time
    - If you're using the helper vm for internal DNS, the only external DNS entries required are:
      - api.`cluster_id`.`base_domain`
      - *.apps.`cluster_id`.`base_domain`
    - Point both of those DNS A or CNAME records to either your LoadBalancers or the public IP address of the CoreOS LoadBalancer VM
2. [CoreOS OVA](http://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/) must be uploaded to vCenter as a template.

## Installation Process

```bash
$ git clone https://github.com/ibm-cloud-architecture/terraform-openshift4-vmware
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
| vsphere_user | vSphere username                                             | string | - |
| vsphere_password             | vSphere password                                             | string | - |
| vsphere_datacenter           | vSphere Datacenter where OpenShift will be deployed          | string | - |
| vsphere_cluster              | vSphere Cluster where OpenShift will be deployed             | string | - |
| vsphere_datastore       | vSphere Datastore for OpenShift nodes                        | string | - |
| vm_template | Name of CoreOS OVA template from prereq #2 | string | - |
| vm_network | vSphere Network for OpenShift nodes                   | string | - |
| loadbalancer_network       | vSphere Network for Loadbalancer/DNS VM                      | string | -                              |
| vm_dns_addresses           | List of DNS servers to use for your OpenShift Nodes          | list   | 8.8.8.8, 8.8.4.4               |
| cluster_id                 | This cluster id must be of max length 27 and must have only alphanumeric or hyphen characters. | string | -                              |
| base_domain                | Base domain for your OpenShift Cluster                       | string | -                              |
| machine_cidr | CIDR for your CoreOS VMs in `subnet/mask` format.            | string | -                              |
|bootstrap_ip_address|IP Address for bootstrap node|string|-|
|control_plane_ip_addresses|List of IP addresses for your control plane nodes|list|-|
| control_plane_count          | Number of control plane VMs to create                        | string | 3                |
| control_plane_memory         | Memory, in MB, to allocate to control plane VMs              | string | 16384            |
|control_plane_num_cpus| Number of CPUs to allocate for control plane VMs             |string|4|
|compute_ip_addresses|List of IP addresses for your compute nodes|list|-|
|compute_count|Number of compute VMs to create|string|3|
|compute_memory|Memory, in MB, to allocate to compute VMs|string|8192|
|compute_num_cpus|Number of CPUs to allocate for compute VMs|string|3|
|storage_ip_addresses|List of IP addresses for your storage nodes|list|`Empty`|
|storage_count|Number of storage VMs to create|string|0|
| storage_memory               | Memory, in MB to allocate to storage VMs                     | string | 65536            |
| storage_num_cpus             | Number of CPUs to allocate for storage VMs                   | string | 16               |
| lb_ip_address                | IP Address for LoadBalancer VM on same subnet as `machine_cidr` | string | -                |
| loadbalancer_lb_ip_address   | IP Address for LoadBalancer VM for secondary NIC on same subnet as `loadbalancer_lb_machine_cidr` | string | -                |
| loadbalancer_lb_machine_cidr | CIDR for your LoadBalancer CoreOS VMs in `subnet/mask` format | string | -                |
| openshift_pull_secret        | Path to your OpenShift pull secret.  Download from https://cloud.redhat.com/openshift/install/vsphere/user-provisioned | string | -                |
| openshift_cluster_cidr       | CIDR for pods in the OpenShift SDN                           | string | 10.128.0.0/14    |
| openshift_service_cidr       | CIDR for services in the OpenShift SDN                       | string | 172.30.0.0/16    |
| openshift_host_prefix        | Controls the number of pods to allocate to each node from the `openshift_cluster_cidr` CIDR. For example, 23 would allocate 2^(32-23) 512 pods to each node. | string | 23               |
| openshift_version            | Version of OpenShift to install. 4.6 or later.               | string | 4.6              |
| create_loadbalancer_vm | Create the LoadBalancer VM and use it as a DNS server for your cluster.  If set to `false` you must provide a valid pre-configured LoadBalancer for your `api` and `*.apps` endpoints and DNS Zone for your `cluster_id`.`base_domain`. | bool | true |
