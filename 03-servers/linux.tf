# ==============================================================================
# OCI Compute Instance: Xubuntu Desktop
# ------------------------------------------------------------------------------
# Purpose:
#   - Deploys the Xubuntu XRDP desktop instance using the Packer-built image.
#   - Joined to the Samba domain, mounts OCI FSS, and serves as Samba gateway.
#   - Launched into the public subnet with a public IP for RDP (XRDP) access.
#
# Shape: E4.Flex 4 OCPU / 16 GB — equivalent to AWS m5.xlarge for a desktop.
# ==============================================================================

resource "oci_core_instance" "xubuntu_instance" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = local.compartment_ocid
  shape               = "VM.Standard.E4.Flex"
  display_name        = local.xubuntu_hostname

  shape_config {
    ocpus         = 4
    memory_in_gbs = 16
  }

  source_details {
    source_type = "image"
    # Packer-built image OCID resolved by apply.sh and passed as a variable
    source_id   = var.xubuntu_image_ocid
  }

  create_vnic_details {
    subnet_id        = local.vm_subnet_ocid
    assign_public_ip = true
    nsg_ids          = [
      oci_core_network_security_group.ssh_nsg.id,
      oci_core_network_security_group.rdp_nsg.id,
      oci_core_network_security_group.smb_nsg.id,
    ]
  }

  metadata = {
    ssh_authorized_keys = local.ssh_public_key
    user_data = base64encode(templatefile("./scripts/userdata.sh", {
      admin_password    = local.admin_password
      domain_fqdn       = var.dns_zone
      domain_fqdn_upper = upper(var.dns_zone)
      netbios           = var.netbios
      dc_ip             = local.dc_private_ip
      mt_ip             = oci_file_storage_mount_target.fss_mt.ip_address
    }))
  }

  # FSS mount target must exist before instance boots and runs userdata
  depends_on = [oci_file_storage_export.nfs_export]
}
