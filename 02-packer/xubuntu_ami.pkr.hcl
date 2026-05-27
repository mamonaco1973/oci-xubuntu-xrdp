# ==============================================================================
# Packer Build: Xubuntu AMI on Ubuntu 24.04 (Noble)
# ------------------------------------------------------------------------------
# Purpose:
#   - Build a custom AMI for Xubuntu + XRDP.
#   - Start from Canonical Ubuntu 24.04 (Noble) AMI.
#   - Run provisioning scripts to install desktop and tools.
#   - Output a timestamped AMI for Terraform or EC2 launches.
#
# Notes:
#   - Requires outbound internet during provisioning.
#   - vpc_id/subnet_id may be empty to use default network.
# ==============================================================================


# ------------------------------------------------------------------------------
# Packer Plugin Configuration
# ------------------------------------------------------------------------------
# Defines the Amazon plugin used to interact with AWS services.
# ------------------------------------------------------------------------------
packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon" # Official HashiCorp plugin.
      version = "~> 1"                        # Compatible versions in v1.
    }
  }
}


# ------------------------------------------------------------------------------
# Data Source: Base Ubuntu 24.04 AMI
# ------------------------------------------------------------------------------
# Fetches the most recent Canonical-owned Ubuntu 24.04 (Noble) AMI.
# ------------------------------------------------------------------------------
data "amazon-ami" "ubuntu_2404" {
  filters = {
    name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
    virtualization-type = "hvm"
    root-device-type    = "ebs"
  }

  most_recent = true
  owners      = ["099720109477"] # Canonical AWS account ID.
}


# ------------------------------------------------------------------------------
# Variables: Build-Time Inputs
# ------------------------------------------------------------------------------
# Controls region, instance type, and optional VPC/subnet placement.
# ------------------------------------------------------------------------------
variable "region" {
  default = "us-east-1" # Default AWS region.
}

variable "instance_type" {
  default = "m5.2xlarge" # Larger build instance for faster provisioning.
}

variable "vpc_id" {
  description = "The ID of the VPC to use."
  default     = ""
}

variable "subnet_id" {
  description = "The ID of the subnet to use."
  default     = ""
}


# ------------------------------------------------------------------------------
# Amazon-EBS Source Block
# ------------------------------------------------------------------------------
# Launches a temporary instance from the base AMI and creates a reusable AMI.
# ------------------------------------------------------------------------------
source "amazon-ebs" "xubuntu_ami" {
  region        = var.region
  instance_type = var.instance_type
  source_ami    = data.amazon-ami.ubuntu_2404.id
  ssh_username  = "ubuntu"
  ami_name      = "xubuntu_ami_${replace(timestamp(), ":", "-")}"
  ssh_interface = "public_ip"
  vpc_id        = var.vpc_id
  subnet_id     = var.subnet_id

  # ---------------------------------------------------------------------------
  # Root EBS Volume Configuration
  # ---------------------------------------------------------------------------
  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = "64"
    volume_type           = "gp3"
    delete_on_termination = "true"
  }

  tags = {
    Name = "xubuntu_ami_${replace(timestamp(), ":", "-")}"
  }
}


# ------------------------------------------------------------------------------
# Build Block: Provisioning Scripts
# ------------------------------------------------------------------------------
# Runs scripts in order to install desktop components and developer tooling.
# ------------------------------------------------------------------------------
build {
  sources = ["source.amazon-ebs.xubuntu_ami"]

  # Install base packages and dependencies.
  provisioner "shell" {
    script          = "./packages.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install Xubuntu desktop.
  provisioner "shell" {
    script          = "./xubuntu.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install XRDP (RDP server).
  provisioner "shell" {
    script          = "./xrdp.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install Google Chrome.
  provisioner "shell" {
    script          = "./chrome.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install Firefox.
  provisioner "shell" {
    script          = "./firefox.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install VS Code.
  provisioner "shell" {
    script          = "./vscode.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install HashiCorp tools.
  provisioner "shell" {
    script          = "./hashicorp.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install AWS CLI.
  provisioner "shell" {
    script          = "./awscli.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install Azure CLI.
  provisioner "shell" {
    script          = "./azcli.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install Google Cloud CLI.
  provisioner "shell" {
    script          = "./gcloudcli.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install Docker.
  provisioner "shell" {
    script          = "./docker.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install Postman.
  provisioner "shell" {
    script          = "./postman.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install KRDC (RDP client).
  provisioner "shell" {
    script          = "./krdc.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install OnlyOffice.
  provisioner "shell" {
    script          = "./onlyoffice.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install desktop icons / shortcuts.
  provisioner "shell" {
    script          = "./desktop.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }
}
