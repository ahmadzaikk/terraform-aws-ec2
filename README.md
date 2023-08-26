# terraform-aws-ec2
Terraform AWS EC2 Module


-->

Terraform module to provision AWS [`EC2`]



## Introduction

The module will create:

* EC2 Instance


## Usage
1. Create main.tf config file, copy/past the following configuration.

## Operating system selection

|Operating system|
|--------------------|
| amazon             |
| amazon2            |
| centos7            |
| centos8            |
| rhel6              |
| rhel7              |
| rhel8              |
| ubuntu1804         |
| ubuntu1810         |
| ubuntu1904         |
| windows2019        |
| windows2019SQL2016E|
| windows2016        |
| windows2012r2      |
| customlinux        |
| customlwin         |


```hcl

#
#

# make sure you deploy the security group before creating ec2 instance, ec2 instance depends on the security group.



provider "aws" {
  region = "us-west-2"
}

module "ec2" {
  source = "git::https://git@github.com/ucopacme/terraform-aws-ec2.git//?ref=v0.0.30"
  enabled                = true          # change it to false to destory the ec2 instance
  os                     = "windows2016" # List of os(amazon,amazon2,centos7,centos8,rhel6,rhel7,rhel8,ubuntu1804,ubuntu1810,ubuntu1904,windows2019,windows2016,windows2012r2,windows2019SQL2016E)
  instance_type          = "r5.4xlarge"  # Default type is t2.micro
  subnet_id              = "subnet_id"
  vpc_security_group_ids = "security_group_ids"
  key_name               = "xxxx" # enter the key name
  root_volume_size       = 150   # Default size is 100GB
  root_volume_encryption = true  # Default is true, Change it to False to create unencrypted root volume
  volume_type            = "gp3" # Default type is gp3
  enabled_eip            = false # Default is false ,chnage it to true to add EIP
  enabled_ebs_volume1    = true  # Default is false, change it to true to add ebs volume 1 (device_name = "/dev/sdh")
  ebs_volume1_size       = 50    # Default null
  snapshot_id_volume1    = ""    # Default null
  enabled_ebs_volume2    = true  # Default is false, change it to true to add ebs volume 2 (device_name = "/dev/sdf")
  ebs_volume2_size       = 150   # Default null
  snapshot_id_volume2    = ""    # Default null
  enabled_ebs_volume3    = true  # Default is false, change it to true to add ebs volume 3 (device_name = "/dev/sdj")
  ebs_volume3_size       = 150   # Default null
  snapshot_id_volume3    = ""    # Default null
  enabled_ebs_volume4    = true  # Default is false, change it to true to add ebs volume 4 (device_name = "/dev/sdi")
  ebs_volume4_size       = 400   # Default null
  snapshot_id_volume4    = ""    # Default null
  enabled_ebs_volume5    = false # Default is false, change it to true to add ebs volume 5 (device_name = "/dev/sdk")
  ebs_volume5_size       = 10    # Default null
  snapshot_id_volume5    = ""    # Default null
  tags = {
    "ucop:application" = "xxx"
    "ucop:createdBy"   = "terraform"
    "ucop:environment" = "xxx"
    "ucop:group"       = "xxx"
    "ucop:source"      = "https://github.com/ucopacme/ucop-terraform-deployments/terraform/xxx/"
    "Name"             = "xxx"
    "ucop:owner"       = "xxx"
  }
}

2. Create output.tf config file, copy/past the following configuration.

output "instance_name" {
description = "The tag name for this instance"
value = var.tags.Name
}
output "instance_id" {
  description = "Instance ID"
  value       = join("", aws_instance.this.*.id)
}
output "instance_arn" {
  description = "Instance ID"
  value       = join("", aws_instance.this.*.arn)
}
output "instance_public_ip" {
  description = "Instance ip"
  value       = join("", aws_instance.this.*.public_ip)
}
output "instance_private_ip" {
  description = "Instance ip"
  value       = join("", aws_instance.this.*.private_ip)
}


