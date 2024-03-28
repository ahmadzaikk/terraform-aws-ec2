variable "ami" {
  description = "(Optional) Amazon Machine Image"
  type        = string
  default     = ""
}
variable "ignore_instance_type_change" {
  type    = bool
  default = true
}

variable "ignore_changes" {
  type    = list
  default = ["ami","associate_public_ip_address"]  # Add other attributes here
}
variable "core_count" {
  type        = number
  description = "custom vcpu count"
  default     = null
}

variable "threads_per_core" {
  type        = number
  description = "custom threads count"
  default     = null
}

variable "associate_public_ip_address" {
  default     = false
  description = "(Optional) Associate a public ip address with an instance in a VPC. Boolean value."
  type        = bool
}

variable "enabled_eip" {
  default     = false
  description = "(Optional) Associate a public ip address with an instance in a VPC. Boolean value."
  type        = bool
}

variable "enabled" {
  type        = string
  description = "Set to `false` to prevent the module from creating any resources"
  default     = "true"
}

variable "root_volume_encryption" {
  type        = bool
  description = "Set to `false` to prevent encyption"
  default     = true
}

variable "enabled_ebs_volume1" {
  type        = bool
  description = "Set to `false` to prevent the module from creating secondary EBS volume"
  default     = false
}

variable "enabled_ebs_volume2" {
  type        = bool
  description = "Set to `false` to prevent the module from creating secondary EBS volume"
  default     = false
}

variable "enabled_ebs_volume3" {
  type        = bool
  description = "Set to `false` to prevent the module from creating secondary EBS volume"
  default     = false
}

variable "enabled_ebs_volume4" {
  type        = bool
  description = "Set to `false` to prevent the module from creating secondary EBS volume"
  default     = false
}

variable "enabled_ebs_volume5" {
  type        = bool
  description = "Set to `false` to prevent the module from creating secondary EBS volume"
  default     = false
}

variable "enabled_ebs_volume6" {
  type        = bool
  description = "Set to `false` to prevent the module from creating secondary EBS volume"
  default     = false
}

variable "instance_type" {
  default     = null
  description = "instance_type"
  type        = string
}

variable "subnet_id" {
  description = "Subnet Id"
  type        = string
  default     = ""
}

variable "tags" {
  default     = {}
  description = "A map of tags to add to all resources"
  type        = map(string)
}

variable "root_volume_size" {
  type        = number
  description = "Size of the root volume in gigabytes"
  default     = 100
}

variable "snapshot_id_volume1" {
  type        = string
  description = "snapshot ID of the volume"
  default     = null
}

variable "snapshot_id_volume2" {
  type        = string
  description = "snapshot ID of the volume"
  default     = null
}

variable "snapshot_id_volume3" {
  type        = string
  description = "snapshot ID of the volume"
  default     = null
}

variable "snapshot_id_volume4" {
  type        = string
  description = "snapshot ID of the volume"
  default     = null
}

variable "snapshot_id_volume5" {
  type        = string
  description = "snapshot ID of the volume"
  default     = null
}

variable "snapshot_id_volume6" {
  type        = string
  description = "snapshot ID of the volume"
  default     = null
}

variable "ebs_volume1_size" {
  type        = number
  description = "size of ebs volume"
  default     = null
}

variable "ebs_volume2_size" {
  type        = number
  description = "size of ebs volume"
  default     = null
}
variable "ebs_volume3_size" {
  type        = number
  description = "size of ebs volume"
  default     = null
}
variable "ebs_volume4_size" {
  type        = number
  description = "size of ebs volume"
  default     = null
}
variable "ebs_volume5_size" {
  type        = number
  description = "size of ebs volume"
  default     = null
}

variable "ebs_volume6_size" {
  type        = number
  description = "size of ebs volume"
  default     = null
}

variable "volume_type" {
  type        = string
  description = "volume_type"
  default     = "gp3"
}

variable "key_name" {
  type        = string
  description = "EC2 key"
  default     = ""
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "Security group IDs to associate with the EC2"
  default     = null
}

variable "instance_profile" {
  type        = string
  description = "IAM instance profile to associate with the EC2"
  default     = null
}

variable "metadata_http_tokens" {
  type        = string
  description = "`required` to enforce IMDSv2, `optional` to allow IMDSv1"
  default     = "required"
}

variable "ebs_optimized" {
  type        = bool
  default     = true
  description = "If true, the launched EC2 instance will be EBS-optimized."
}

variable "monitoring" {
  type        = bool
  default     = false
  description = "If true, the launched EC2 instance will have detailed monitoring enabled. (Available since v0.6.0)."
}

variable "disable_api_termination" {
  type        = bool
  default     = false
  description = "If true, enables EC2 Instance Termination Protection."
}
variable "user_data" {
  type        = string
  default     = ""
  description = "(Optional) A string of the desired User Data for the ec2."
}

variable "vcpu_count" {
  type        = number
  description = "Number of desired vCPUs (used to auto-select instance type from ec2_instance_map)"
  default     = null
  validation {
    condition = var.vcpu_count == null ? true : contains(
      [2, 4, 8, 16, 32],
      var.vcpu_count
    )
    error_message = "var.vcpu_count is not valid, choices are: 2,4,8,16,32."
  }
}

variable "memory_gb" {
  type        = number
  description = "GB of desired memory (used to auto-select instance type from ec2_instance_map)"
  default     = null
  validation {
    condition = var.memory_gb == null ? true : contains(
      [1, 2, 4, 8, 16, 32, 64, 128, 256],
      var.memory_gb
    )
    error_message = "var.memory_gb is not valid, choices are: 1,2,4,8,16,32,64,128,256."
  }
}

# AMI search

variable "os" {
  description = "The OS reference to search for"
  default     = "al2023"
}

variable "amis_primary_owners" {
  description = "Force the ami Owner, could be (self) or specific (id)"
  default     = ""
}

variable "amis_os_map_regex" {
  description = "Map of regex to search amis"
  type        = map(any)

  default = {
    ubuntu1804          = "^ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-.*"
    ubuntu1810          = "^ubuntu/images/hvm-ssd/ubuntu-cosmic-18.10-amd64-server-.*"
    ubuntu1904          = "^ubuntu/images/hvm-ssd/ubuntu-disco-19.04-amd64-server-.*"
    centos7             = "CentOS.Linux.7.*x86_64.*"
    centos8             = "CentOS.Linux.8.*x86_64.*"
    rhel6               = "^RHEL-6.*x86_64.*"
    rhel7               = "^RHEL-7.*x86_64.*"
    rhel8               = "^RHEL-8.9.*x86_64.*"
    rhel9               = "^RHEL-9.*x86_64.*"
    amazon2             = "^amzn2-ami-hvm-.*x86_64-gp2"
    al2023              = "^al2023-ami-2023.*x86_64"
    windows2022         = "^Windows_Server-2022-English-Full-Base-.*"
    windows2019         = "^Windows_Server-2019-English-Full-Base-.*"
    windows2019SQL2016E = "^Windows_Server-2019-English-Full-SQL_2016_SP3_Enterprise-.*"
    windows2016         = "^Windows_Server-2016-English-Full-Base-.*"
    windows2012r2       = "^Windows_Server-2012-R2_RTM-English-64Bit-Base-.*"
    customlinux         = "custom-linux-ami*"
    customwin           = "custom-win-ami*"
    customrhel7         = "custom-rhel7-ami*"
  }
}

variable "amis_os_map_owners" {
  description = "Map of amis owner to filter only official amis"
  type        = map(any)
  default = {
    ubuntu1804          = "099720109477" #CANONICAL
    ubuntu1810          = "099720109477" #CANONICAL
    ubuntu1904          = "099720109477" #CANONICAL
    rhel6               = "309956199498" #Amazon Web Services
    rhel7               = "309956199498" #Amazon Web Services
    rhel8               = "309956199498" #Amazon Web Services
    rhel9               = "309956199498" #Amazon Web Services
    centos7             = "679593333241"
    centos8             = "679593333241"
    amazon2             = "137112412989" #amazon
    al2023              = "137112412989" #amazon
    windows2019         = "801119661308" #amazon
    windows2019SQL2016E = "801119661308" #amazon
    windows2022         = "801119661308" #amazon
    windows2016         = "801119661308" #amazon
    windows2012r2       = "801119661308" #amazon
    customlinux         = "self"
    customwin           = "self"
    customrhel7         = "self"
  }
}

variable "ec2_instance_map" {
  description = "Map of EC2 instance type/sizes based on vCPU, memory"
  type        = map(map(string))

  default = {
    2 = {
      1  = "t3a.micro"
      2  = "t3a.small"
      4  = "t3a.medium"
      8  = "t3a.large"
      16 = "r7a.large"
    }
    4 = {
      8  = "c7a.xlarge"
      16 = "t3a.xlarge"
      32 = "r7a.xlarge"
    }
    8 = {
      16 = "c7a.2xlarge"
      32 = "t3a.2xlarge"
      64 = "r7a.2xlarge"
    }
    16 = {
      32  = "c7a.4xlarge"
      64  = "m7i-flex.4xlarge"
      128 = "r7a.4xlarge"
    }
    32 = {
      64  = "c7a.8xlarge"
      128 = "m7i-flex.8xlarge"
      256 = "r7a.8xlarge"
    }
  }
}

variable "base_user_data" {
  description = "Map of base user_data to run for a given OS string"
  type        = map(string)

  default = {
    al2023 = <<-EOF
             #!/bin/bash
             cd /tmp
             sudo dnf install -y amazon-cloudwatch-agent
             sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:AmazonCloudWatch-CWAgentLinuxBaseConfig
             if [ $? -eq 0 ]; then
               sudo systemctl enable amazon-cloudwatch-agent
               sudo systemctl start amazon-cloudwatch-agent
             fi
           EOF
    amazon2 = <<-EOF
              #!/bin/bash
              cd /tmp
              sudo yum install -y amazon-cloudwatch-agent
              sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:AmazonCloudWatch-CWAgentLinuxBaseConfig
              if [ $? -eq 0 ]; then
                sudo systemctl enable amazon-cloudwatch-agent
                sudo systemctl start amazon-cloudwatch-agent
              fi
            EOF
    rhel7 = <<-EOF
            #!/bin/bash
            cd /tmp
            sudo yum install -y \
              https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm \
              https://amazoncloudwatch-agent-us-west-2.s3.us-west-2.amazonaws.com/redhat/amd64/latest/amazon-cloudwatch-agent.rpm
            sudo systemctl enable amazon-ssm-agent
            sudo systemctl start amazon-ssm-agent
            sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:AmazonCloudWatch-CWAgentLinuxBaseConfig
            if [ $? -eq 0 ]; then
              sudo systemctl enable amazon-cloudwatch-agent
              sudo systemctl start amazon-cloudwatch-agent
            fi
          EOF
    rhel8 = <<-EOF
            #!/bin/bash
            cd /tmp
            sudo dnf install -y python3
            sudo dnf install -y \
              https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm \
              https://amazon-ec2-instance-connect-us-west-2.s3.us-west-2.amazonaws.com/latest/linux_amd64/ec2-instance-connect.rhel8.rpm \
              https://amazon-ec2-instance-connect-us-west-2.s3.us-west-2.amazonaws.com/latest/linux_amd64/ec2-instance-connect-selinux.noarch.rpm \
              https://amazoncloudwatch-agent-us-west-2.s3.us-west-2.amazonaws.com/redhat/amd64/latest/amazon-cloudwatch-agent.rpm
            sudo systemctl enable amazon-ssm-agent
            sudo systemctl start amazon-ssm-agent
            sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:AmazonCloudWatch-CWAgentLinuxBaseConfig
            if [ $? -eq 0 ]; then
              sudo systemctl enable amazon-cloudwatch-agent
              sudo systemctl start amazon-cloudwatch-agent
            fi
          EOF
    rhel9 = <<-EOF
            #!/bin/bash
            cd /tmp
            sudo dnf install -y python3
            sudo dnf install -y \
              https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm \
              https://amazon-ec2-instance-connect-us-west-2.s3.us-west-2.amazonaws.com/latest/linux_amd64/ec2-instance-connect.rpm \
              https://amazon-ec2-instance-connect-us-west-2.s3.us-west-2.amazonaws.com/latest/linux_amd64/ec2-instance-connect-selinux.noarch.rpm \
              https://amazoncloudwatch-agent-us-west-2.s3.us-west-2.amazonaws.com/redhat/amd64/latest/amazon-cloudwatch-agent.rpm
            sudo systemctl enable amazon-ssm-agent
            sudo systemctl start amazon-ssm-agent
            sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:AmazonCloudWatch-CWAgentLinuxBaseConfig
            if [ $? -eq 0 ]; then
              sudo systemctl enable amazon-cloudwatch-agent
              sudo systemctl start amazon-cloudwatch-agent
            fi
          EOF
    windows2016 = <<-EOF
                  <powershell>
                  Start-Process msiexec.exe -Wait -ArgumentList '/i https://amazoncloudwatch-agent-us-west-2.s3.us-west-2.amazonaws.com/windows/amd64/latest/amazon-cloudwatch-agent.msi /quiet /qn'
                  & "C:\Program Files\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent-ctl.ps1" -a fetch-config -m ec2 -s -c ssm:AmazonCloudWatch-CWAgentWindowsBaseConfig
                  </powershell>
                EOF
    windows2019 = <<-EOF
                  <powershell>
                  Start-Process msiexec.exe -Wait -ArgumentList '/i https://amazoncloudwatch-agent-us-west-2.s3.us-west-2.amazonaws.com/windows/amd64/latest/amazon-cloudwatch-agent.msi /quiet /qn'
                  & "C:\Program Files\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent-ctl.ps1" -a fetch-config -m ec2 -s -c ssm:AmazonCloudWatch-CWAgentWindowsBaseConfig
                  </powershell>
                EOF
    windows2022 = <<-EOF
                  <powershell>
                  Start-Process msiexec.exe -Wait -ArgumentList '/i https://amazoncloudwatch-agent-us-west-2.s3.us-west-2.amazonaws.com/windows/amd64/latest/amazon-cloudwatch-agent.msi /quiet /qn'
                  & "C:\Program Files\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent-ctl.ps1" -a fetch-config -m ec2 -s -c ssm:AmazonCloudWatch-CWAgentWindowsBaseConfig
                  </powershell>
                EOF
  }
}
