# create Virtual Machine
# REF: https://www.hashicorp.com/blog/a-re-introduction-to-the-terraform-vsphere-provider

# execute by
# terraform plan -var-file=Swarm/swarm.tfvars -state=Swarm/swarm.tfstate

# start define variable

provider "vsphere" {
    user = "administrator@vsphere.local"
    password = "VMware1!"
    vsphere_server = "vcdr01.ldc.int"  
    allow_unverified_ssl = true
}
data "vsphere_datacenter" "dc" {
  name = "DR-Sky"
}
data "vsphere_datastore" "datastore" {
  name          = "LSI-SSD00.local"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_compute_cluster" "cluster" {
  name          = "DR-Main"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "V1720"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "CentOS7-DR"
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
                domain    = "test.internal"
            }

            network_interface {
                ipv4_address = "${lookup(var.ipv4, count.index)}"
                ipv4_netmask = "${var.subnet}"
            }

            ipv4_gateway = "${var.gateway}"
        }
    }

}
