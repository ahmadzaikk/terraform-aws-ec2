# user_data including a base value for given var.os, and also var.user_data.
# (Note Cloud-init is applicable only for Linux).
locals {
  enabled = var.enabled == "true"

  # Compose cloud-init parts (shell scripts) - Linux only
  cloudinit_parts = compact([
    contains(keys(var.base_user_data), var.os) ? var.base_user_data[var.os] : null,
    var.user_data != "" ? var.user_data : null
  ])

  # Determine vCPU and memory with fallback logic
  vcpu_count = coalesce(
    var.vcpu_count,
    var.memory_gb != null ? min([for k, v in var.ec2_instance_map : k if contains(keys(v), tostring(var.memory_gb))]...) : 2
  )

  memory_gb = coalesce(
    var.memory_gb,
    var.vcpu_count != null ? min(keys(lookup(var.ec2_instance_map, var.vcpu_count, {}))...) : 1
  )

  instance_type = coalesce(
    var.instance_type,
    lookup(lookup(var.ec2_instance_map, local.vcpu_count, {}), local.memory_gb, "")
  )

  # Compose raw user data string depending on OS and raw_user_data
  # For Linux, user_data_raw is the base64 output from cloudinit_config
  # For Windows, base64 encode user_data or base_user_data string manually

  user_data_raw = var.raw_user_data != "" ? var.raw_user_data : (
    length(regexall("^windows", var.os)) == 0 ?
      data.cloudinit_config.this.rendered : (
      (contains(keys(var.base_user_data), var.os) && var.user_data == "") ? base64encode(var.base_user_data[var.os]) : base64encode(var.user_data)
    )
  )

  # Use user_data_raw directly as user_data_base64 because for Linux
  # it is already base64, and for Windows we just base64 encoded above
  user_data = local.user_data_raw


data "cloudinit_config" "this" {
  gzip          = false
  base64_encode = true  # Keep false, so .rendered is plain text (will base64 encode later)

  dynamic "part" {
    for_each = local.cloudinit_parts
    content {
      content_type = "text/x-shellscript"
      content      = part.value
    }
  }
}



# Read in ID of common security group created by Firewall Manager.
data "aws_subnet" "subnet" {
  id = var.subnet_id
}

data "aws_security_groups" "fms_security_groups_common_usw2" {
  tags = {
    fms-policy-name = "security_groups_common_usw2"
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_subnet.subnet.vpc_id]
  }
}



data "aws_ami" "search" {
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  name_regex = lookup(var.amis_os_map_regex, var.os)
  owners     = [length(var.amis_primary_owners) == 0 ? lookup(var.amis_os_map_owners, var.os) : var.amis_primary_owners]
}


# resource block for ec2 #
resource "aws_instance" "this" {
  count                       = local.enabled ? 1 : 0
  ami                         = var.ami != "" ? var.ami : data.aws_ami.search.id
  associate_public_ip_address = var.associate_public_ip_address
  disable_api_termination     = var.disable_api_termination
  ebs_optimized               = var.ebs_optimized
  iam_instance_profile        = var.instance_profile
  instance_type               = local.instance_type
  monitoring                  = var.monitoring
  subnet_id                   = var.subnet_id
  tags                        = var.tags
  vpc_security_group_ids      = concat(var.vpc_security_group_ids, data.aws_security_groups.fms_security_groups_common_usw2.ids)
  key_name                    = var.key_name
  user_data_base64                   = local.user_data
  cpu_options {
    core_count       = var.core_count
    threads_per_core = var.threads_per_core
  }


  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.volume_type
    encrypted   = var.root_volume_encryption
    tags        = var.tags
  }
  lifecycle {
    # ignore_changes = [ami,ebs_block_device,root_block_device,associate_public_ip_address]
    ignore_changes = [tags["ResourceGroup"],tags["ucop:AWSPatchPolicy"],root_block_device[0].tags["ucop:prePatchEbsSnapshot"],ami,associate_public_ip_address,user_data,user_data_base64]
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = var.metadata_http_tokens
    instance_metadata_tags      = var.instance_metadata_tags
  }
}


# resource block for eip #
resource "aws_eip" "this" {
  count    = var.enabled_eip ? 1 : 0
#  domain   = "vpc"
  tags     = var.tags
}

# resource block for ec2 and eip association #
resource "aws_eip_association" "eip_assoc" {
  count    = var.enabled_eip ? 1 : 0
  instance_id   = aws_instance.this.*.id[0]
  allocation_id = aws_eip.this.*.id[0]

}
# resource block for ebs volumes #
resource "aws_ebs_volume" "this" {
  count             = var.enabled_ebs_volume1 ? 1 : 0
  size              = var.ebs_volume1_size
  type              = var.volume_type
  snapshot_id       = var.snapshot_id_volume1
  availability_zone = aws_instance.this.*.availability_zone[0]
  tags                        = var.tags
  lifecycle {
    ignore_changes = [availability_zone]
  }
}

resource "aws_volume_attachment" "this" {
  count       = var.enabled_ebs_volume1 ? 1 : 0
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.this.*.id[0]
  instance_id = aws_instance.this.*.id[0]
  lifecycle {
    ignore_changes = [instance_id,volume_id]
  }
}

resource "aws_ebs_volume" "vol2" {
  count             = var.enabled_ebs_volume2 ? 1 : 0
  size              = var.ebs_volume2_size
  type              = var.volume_type
  snapshot_id       = var.snapshot_id_volume2
  availability_zone = aws_instance.this.*.availability_zone[0]
  tags                        = var.tags
  lifecycle {
    ignore_changes = [availability_zone]
  }
}

resource "aws_volume_attachment" "attachment2" {
  count       = var.enabled_ebs_volume2 ? 1 : 0
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.vol2.*.id[0]
  instance_id = aws_instance.this.*.id[0]
  lifecycle {
    ignore_changes = [instance_id,volume_id]
  }
}

resource "aws_ebs_volume" "vol3" {
  count             = var.enabled_ebs_volume3 ? 1 : 0
  size              = var.ebs_volume3_size
  type              = var.volume_type
  snapshot_id       = var.snapshot_id_volume3
  availability_zone = aws_instance.this.*.availability_zone[0]
  tags                        = var.tags
  lifecycle {
    ignore_changes = [availability_zone]
  }
}

resource "aws_volume_attachment" "attachment3" {
  count       = var.enabled_ebs_volume3 ? 1 : 0
  device_name = "/dev/sdj"
  volume_id   = aws_ebs_volume.vol3.*.id[0]
  instance_id = aws_instance.this.*.id[0]
  lifecycle {
    ignore_changes = [instance_id,volume_id]
  }
}

resource "aws_ebs_volume" "vol4" {
  count             = var.enabled_ebs_volume4 ? 1 : 0
  size              = var.ebs_volume4_size
  type              = var.volume_type
  snapshot_id       = var.snapshot_id_volume4
  availability_zone = aws_instance.this.*.availability_zone[0]
  tags                        = var.tags
  lifecycle {
    ignore_changes = [availability_zone]
  }
}

resource "aws_volume_attachment" "attachment4" {
  count       = var.enabled_ebs_volume4 ? 1 : 0
  device_name = "/dev/sdi"
  volume_id   = aws_ebs_volume.vol4.*.id[0]
  instance_id = aws_instance.this.*.id[0]
  lifecycle {
    ignore_changes = [instance_id,volume_id]
  }
}

resource "aws_ebs_volume" "vol5" {
  count             = var.enabled_ebs_volume5 ? 1 : 0
  size              = var.ebs_volume5_size
  type              = var.volume_type
  snapshot_id       = var.snapshot_id_volume5
  availability_zone = aws_instance.this.*.availability_zone[0]
  tags                        = var.tags
  lifecycle {
    ignore_changes = [availability_zone]
  }
}

resource "aws_volume_attachment" "attachment5" {
  count       = var.enabled_ebs_volume5 ? 1 : 0
  device_name = "/dev/sdk"
  volume_id   = aws_ebs_volume.vol5.*.id[0]
  instance_id = aws_instance.this.*.id[0]
  lifecycle {
    ignore_changes = [instance_id,volume_id]
  }
}

resource "aws_ebs_volume" "vol6" {
  count             = var.enabled_ebs_volume6 ? 1 : 0
  size              = var.ebs_volume6_size
  type              = var.volume_type
  snapshot_id       = var.snapshot_id_volume6
  availability_zone = aws_instance.this.*.availability_zone[0]
  tags                        = var.tags
  lifecycle {
    ignore_changes = [availability_zone]
  }
}

resource "aws_volume_attachment" "attachment6" {
  count       = var.enabled_ebs_volume6 ? 1 : 0
  device_name = "/dev/sdl"
  volume_id   = aws_ebs_volume.vol6.*.id[0]
  instance_id = aws_instance.this.*.id[0]
  lifecycle {
    ignore_changes = [instance_id,volume_id]
  }
}
