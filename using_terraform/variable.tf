# Names
variable "vpc_name" {
  default = "eng_84_ben_terraform_vpc"
}

variable "pub_subnet_name" {
  default = "eng84_ben_terraform_public_subnet"
}

variable "priv_subnet_name" {
  default = "eng84_ben_terraform_private_subnet"
}

variable "igw_name"{
  default = "eng84_ben_terraform_igw"
}

variable "pub_rt_name"{
  default = "eng84_ben_terraform_rt_pub"
}

variable "priv_rt_name"{
  default = "eng84_ben_terraform_rt_priv"
}

variable "pub_sec_name"{
  default = "eng84_ben_terraform_pub_sec"
}

variable "priv_sec_name"{
  default = "eng84_ben_terraform_priv_sec"
}

variable "webapp_name"{
  default = "eng84_ben_terraform_app"
}

variable "db_name"{
  default = "eng84_ben_terraform_db"
}




# CIDR Blocks
variable "vpc_cidr" {
  default = "13.37.0.0/16"
}

variable "pub1_cidr" {
  default = "13.37.1.0/24"
}

variable "pub2_cidr" {
  default = "13.37.3.0/24"
}

variable "priv_cidr" {
  default = "13.37.2.0/24"
}



# Specific ips
variable "my_ip"{
  default = "217.155.15.136/32"
}

variable "webapp_ip"{
  default = "13.37.1.134"
}

variable "db_ip"{
  default = "13.37.2.36"
}



# AMI's
variable "app_ami" {
    default = "ami-0254eef2b468bd3d8"
}

variable "db_ami" {
    default = "ami-04bd986e52b945e92"
}

variable "launch_template_id" {
    default = "lt-06914f67db6d7167d"
}



# Key pair
variable "key"{
  default = "eng84devops"
}

variable "key_path"{
  default = "C:/Users/Ben/.ssh/eng84devops.pem"
}