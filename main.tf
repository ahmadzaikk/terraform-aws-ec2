# user_data including a base value for given var.os, and also var.user_data.
# (Note Cloud-init is applicable only for Linux).
data "cloudinit_config" "this" {
  gzip          = false
  base64_encode = false
  dynamic "part" {
    for_each = [
      contains(keys(var.base_user_data), var.os) ? var.base_user_data[var.os] : "",
      var.user_data
    ]
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

locals {
  enabled = var.enabled == "true"
  vcpu_count = coalesce(var.vcpu_count,
    var.memory_gb != null ? min([for k, v in var.ec2_instance_map : k if contains(keys(v), tostring(var.memory_gb))]...) : 2
  )
  memory_gb = coalesce(var.memory_gb,
    var.vcpu_count != null ? min(keys(lookup(var.ec2_instance_map, var.vcpu_count, {}))...) : 1
  )
  instance_type = coalesce(var.instance_type,
    lookup(lookup(var.ec2_instance_map, local.vcpu_count, {}), local.memory_gb, "")
  )

  # If var.raw_user_data was provided, use that for user_data.
  # Else if non-Windows, use cloudinit_config user_data (see above).
  # Otherwise (for Windows), use var.user_data if defined, else var.base_user_data.
  # (Ideal to-do: find a way to do merged var.user_data and base_user_data on Windows).
  user_data = var.raw_user_data != "" ? var.raw_user_data : (
    length(regexall("^windows", var.os)) == 0 ? data.cloudinit_config.this.rendered : (
      (contains(keys(var.base_user_data), var.os) && var.user_data == "") ? var.base_user_data[var.os] : var.user_data
    )
  )
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
  user_data                   = local.user_data
  cpu_options {
    core_count       = var.core_count
    threads_per_core = var.threads_per_core
  }

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.volume_type
    encrypted   = var.root_volume_encryption
    iops        = contains(["gp3", "io1", "io2"], var.volume_type) ? var.root_volume_iops : null
    throughput  = contains(["gp3"], var.volume_type) ? var.root_volume_throughput : null
    tags        = var.tags
  }
  lifecycle {
    # ignore_changes = [ami,ebs_block_device,root_block_device,associate_public_ip_address]
    ignore_changes = [tags["ResourceGroup"],tags["ucop:AWSPatchPolicy"],root_block_device[0].tags["ucop:prePatchEbsSnapshot"],ami,associate_public_ip_address,user_data]
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
  iops              = contains(["gp3", "io1", "io2"], var.volume_type) ? var.ebs_volume1_iops : null
  throughput        = contains(["gp3"], var.volume_type) ? var.ebs_volume1_throughput : null
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
  iops              = contains(["gp3", "io1", "io2"], var.volume_type) ? var.ebs_volume2_iops : null
  throughput        = contains(["gp3"], var.volume_type) ? var.ebs_volume2_throughput : null
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
  iops              = contains(["gp3", "io1", "io2"], var.volume_type) ? var.ebs_volume3_iops : null
  throughput        = contains(["gp3"], var.volume_type) ? var.ebs_volume3_throughput : null
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
  iops              = contains(["gp3", "io1", "io2"], var.volume_type) ? var.ebs_volume4_iops : null
  throughput        = contains(["gp3"], var.volume_type) ? var.ebs_volume4_throughput : null
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
  iops              = contains(["gp3", "io1", "io2"], var.volume_type) ? var.ebs_volume5_iops : null
  throughput        = contains(["gp3"], var.volume_type) ? var.ebs_volume5_throughput : null
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
  iops              = contains(["gp3", "io1", "io2"], var.volume_type) ? var.ebs_volume6_iops : null
  throughput        = contains(["gp3"], var.volume_type) ? var.ebs_volume6_throughput : null
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

resource "aws_ebs_volume" "vol7" {
  count             = var.enabled_ebs_volume7 ? 1 : 0
  size              = var.ebs_volume7_size
  type              = var.volume_type
  iops              = contains(["gp3", "io1", "io2"], var.volume_type) ? var.ebs_volume7_iops : null
  throughput        = contains(["gp3"], var.volume_type) ? var.ebs_volume7_throughput : null
  snapshot_id       = var.snapshot_id_volume7
  availability_zone = aws_instance.this.*.availability_zone[0]
  tags                        = var.tags
  lifecycle {
    ignore_changes = [availability_zone]
  }
}

resource "aws_volume_attachment" "attachment7" {
  count       = var.enabled_ebs_volume7 ? 1 : 0
  device_name = "/dev/sdm"
  volume_id   = aws_ebs_volume.vol7.*.id[0]
  instance_id = aws_instance.this.*.id[0]
  lifecycle {
    ignore_changes = [instance_id,volume_id]
  }
}

resource "aws_ebs_volume" "vol8" {
  count             = var.enabled_ebs_volume8 ? 1 : 0
  size              = var.ebs_volume8_size
  type              = var.volume_type
  iops              = contains(["gp3", "io1", "io2"], var.volume_type) ? var.ebs_volume8_iops : null
  throughput        = contains(["gp3"], var.volume_type) ? var.ebs_volume8_throughput : null
  snapshot_id       = var.snapshot_id_volume8
  availability_zone = aws_instance.this.*.availability_zone[0]
  tags                        = var.tags
  lifecycle {
    ignore_changes = [availability_zone]
  }
}

resource "aws_volume_attachment" "attachment8" {
  count       = var.enabled_ebs_volume8 ? 1 : 0
  device_name = "/dev/sdn"
  volume_id   = aws_ebs_volume.vol8.*.id[0]
  instance_id = aws_instance.this.*.id[0]
  lifecycle {
    ignore_changes = [instance_id,volume_id]
  }
}

resource "aws_ebs_volume" "vol9" {
  count             = var.enabled_ebs_volume9 ? 1 : 0
  size              = var.ebs_volume9_size
  type              = var.volume_type
  iops              = contains(["gp3", "io1", "io2"], var.volume_type) ? var.ebs_volume9_iops : null
  throughput        = contains(["gp3"], var.volume_type) ? var.ebs_volume9_throughput : null
  snapshot_id       = var.snapshot_id_volume9
  availability_zone = aws_instance.this.*.availability_zone[0]
  tags                        = var.tags
  lifecycle {
    ignore_changes = [availability_zone]
  }
}

resource "aws_volume_attachment" "attachment9" {
  count       = var.enabled_ebs_volume9 ? 1 : 0
  device_name = "/dev/sdo"
  volume_id   = aws_ebs_volume.vol9.*.id[0]
  instance_id = aws_instance.this.*.id[0]
  lifecycle {
    ignore_changes = [instance_id,volume_id]
  }
}
