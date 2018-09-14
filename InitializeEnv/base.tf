# create Virtual Machine

provider "vsphere" {
    user = "administrator@vsphere.local"
    password = "VMware1!"
    vsphere_server = "vcdr01.ldc.int"  
    allow_unverified_ssl = true
}

data "vsphere_datacenter" "DR-Sky" {}

resource "vsphere_folder" "vSphere-Terra" {
    type = "vm"
    path = "vSphere-Terra"  
    datacenter_id = "${data.vsphere_datacenter.DR-Sky.id}"
}
