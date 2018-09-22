# create Virtual Machine

provider "vsphere" {
    user = "administrator@vsphere.local"
    password = "VMware1!"
    vsphere_server = "vcdr01.ldc.int"  
    allow_unverified_ssl = true
}

# start define variable

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

resource "vsphere_folder" "vSphere-Terra" {
    type = "vm"
    path = "vSphere-Terra"  
    datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

# create VM within the folder
resource "vsphere_virtual_machine" "terraform-machine"
{
    name = "terraformMachine"
    folder = "${vsphere_folder.vSphere-Terra.path}"
    resource_pool_id = "${data.vsphere_compute_cluster.cluster.resource_pool_id}"
    datastore_id     = "${data.vsphere_datastore.datastore.id}"
    num_cpus = 2
    memory = 4096
    
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
                host_name = "terraform-test"
                domain    = "test.internal"
            }

            network_interface {
                ipv4_address = "172.16.0.171"
                ipv4_netmask = "24"
            }

            ipv4_gateway = "172.16.0.1"
        }
    }

}
