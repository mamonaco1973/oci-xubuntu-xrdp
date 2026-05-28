# ==============================================================================
# OCI File Storage Service (FSS)
# ------------------------------------------------------------------------------
# Purpose:
#   - Provisions a managed NFS file system equivalent to AWS EFS.
#   - Exposes /nfs as the shared data path; /nfs/home is bind-symlinked to
#     /home so AD user home directories live on FSS across reboots.
#   - The Xubuntu instance re-exports /nfs via Samba (SMB) so Windows clients
#     can map Z: to \\<xubuntu-ip>\nfs.
#
# Scope:
#   - FSS file system (encrypted at rest by default in OCI)
#   - Mount target in vm-subnet (gets a private IP from 10.0.0.64/26)
#   - One export: /nfs
#
# Notes:
#   - OCI FSS requires 3 resources: file_system + mount_target + export(s).
#   - NFS ports (111, 2048-2050) are already open in the vm-subnet security
#     list defined in 01-directory/networking.tf.
#   - Mount target IP is known only after apply — templated into userdata.sh.
# ==============================================================================

# ==============================================================================
# File System
# ==============================================================================

resource "oci_file_storage_file_system" "fss" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = local.compartment_ocid
  display_name        = "xubuntu-fss"
}

# ==============================================================================
# Mount Target
# ------------------------------------------------------------------------------
# Lives in vm-subnet so the Xubuntu instance and mount target share the same
# subnet security list rules for NFS traffic.
# ==============================================================================

resource "oci_file_storage_mount_target" "fss_mt" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = local.compartment_ocid
  subnet_id           = local.vm_subnet_ocid
  display_name        = "xubuntu-fss-mt"
}

# ==============================================================================
# Export
# ------------------------------------------------------------------------------
# /nfs — shared data directory.
#   /nfs/home is symlinked to /home so AD user homes live on FSS.
#   /nfs is re-exported via Samba to Windows as Z:
# ==============================================================================

resource "oci_file_storage_export" "nfs_export" {
  export_set_id  = oci_file_storage_mount_target.fss_mt.export_set_id
  file_system_id = oci_file_storage_file_system.fss.id
  path           = "/nfs"
}
