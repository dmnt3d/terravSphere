# create Virtual Machine
# REF: https://www.hashicorp.com/blog/a-re-introduction-to-the-terraform-vsphere-provider

# execute by
# terraform plan -var-file=Swarm/swarm.tfvars -var-file=DR.tfvars -state=Swarm/swarm.tfstate

# start define variable

provider "vsphere" {
    user = "${var.userName}"
    password = "${var.password}"
    vsphere_server = "${var.vCenter}"
    allow_unverified_ssl = true
}
data "vsphere_datacenter" "dc" {
  name = "${var.datacenter}"
}
data "vsphere_datastore" "datastore" {
  name          = "${var.datastore}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_compute_cluster" "cluster" {
  name          = "${var.cluster}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "${var.network}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "${var.template}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}
# end define variable

resource "vsphere_folder" "vSphere-Folder" {
    type = "vm"
    path = "${var.folder}"  
    datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

# create VM within the folder
resource "vsphere_virtual_machine" "terraform-machine"
{
    #name = "terraformMachine"
    count = "${var.count}"
    name   = "${var.prefix}${format("%02d", count.index + var.start_val)}"
    folder = "${vsphere_folder.vSphere-Folder.path}"
    resource_pool_id = "${data.vsphere_compute_cluster.cluster.resource_pool_id}"
    datastore_id     = "${data.vsphere_datastore.datastore.id}"
    num_cpus = "${var.CPU}"
    memory = "${var.mem}"
    
    guest_id = "${data.vsphere_virtual_machine.template.guest_id}"
    scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

    network_interface {
        network_id   = "${data.vsphere_network.network.id}"
        adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
    }

    disk {
        label = "disk0"
        size = "${data.vsphere_virtual_machine.template.disks.0.size}"
        eagerly_scrub = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
        thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
    }


    clone {
        template_uuid = "${data.vsphere_virtual_machine.template.id}"
        timeout = "60"

        customize {
            linux_options {
                host_name = "${var.prefix}${format("%02d", count.index + var.start_val)}"
                domain    = "${var.prefix}.internal"
            }

            network_interface {
                #ipv4_address = "${lookup(var.ipv4, count.index)}"
                ipv4_address = "${var.ipv4}${count.index+var.start_val}"
                ipv4_netmask = "${var.subnet}"
            }

            ipv4_gateway = "${var.gateway}"
            dns_suffix_list = ["${var.domain}"]
            dns_server_list = ["${var.dns_servers}"]
        }
    }

}
