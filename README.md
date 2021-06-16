# terraform-aws-ec2
Terraform AWS EC2 Module


-->

Terraform module to provision AWS [`EC2`]



## Introduction

The module will create:

* EC2 Instance


## Usage
Create terragrunt.hcl config file, copy/past the following configuration.

```hcl

#
# Include all settings from root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependency "sg" {
  config_path = "../sg"
}
inputs = {
  enabled                      = true
  enabled_ebs_volume           = false # Default is false, change it to true to add scondary ebs volume
  enable_ebs_volume_attachment = false # Default is false, change it to true to attach ebs volume to ec2 insance
  ami                          = "ami-0800fc0fa715fdcfe"
  instance_type                = "t2.micro" # Default type is t2.micro
  subnet_id                    = "subnet-084c56f1fd8699098098"
  vpc_security_group_ids       = [dependency.sg.outputs.id]
  key_name                     = "khalid-chsdev-key"
  root_volume_size             = 50    # Default size is 100GB
  volume_type                  = "gp3" # Default type is gp3
  ebs_volume_size              = 10    # Default null, adding secondary ebs
  tags = {
    "ucop:application" = "test"
    "ucop:createdBy"   = "terraform"
    "ucop:enviroment"  = "Prod"
    "ucop:group"       = "test"
    "ucop:source"      = join("/", ["https://github.com/ucopacme/ucop-terraform-config/tree/master/terraform/its-chs-dev/us-west-2", path_relative_to_include()])
    "Name"             = "test"
    "ucop:owner"       = "chs"
  }
}

terraform {
  source = "git::https://git@github.com/ucopacme/terraform-aws-ec2.git?ref=v0.0.1"
}
