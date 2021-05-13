# Initialize Terraform
# Connect to and use AWS:

# Use the keyword "provider" to define what cloud service we will use:
provider "aws" {
    region = "eu-west-1"
}



# Creating a vpc
resource "aws_vpc" "terraform_vpc"{
    cidr_block = var.vpc_cidr

    tags = {
        Name = var.vpc_name
    }
}
# Create an internet gateway that attaches to our vpc
resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    Name = var.igw_name
  }
}



# Edit the main route table
resource "aws_default_route_table" "terraform_rt_pub" {
  default_route_table_id = aws_vpc.terraform_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_igw.id
  }

  tags = {
    Name = var.pub_rt_name
  }
}
# Create Private route table
resource "aws_route_table" "terraform_rt_priv" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    Name = var.priv_rt_name
  }
}



# Creating a few subnets for out vpc
resource "aws_subnet" "terraform_public_subnet_1"{
    vpc_id = aws_vpc.terraform_vpc.id
    cidr_block = var.pub1_cidr
    availability_zone = "eu-west-1b"
    tags = {
        Name = "${var.pub_subnet_name}-1"
    }
}
resource "aws_subnet" "terraform_public_subnet_2"{
    vpc_id = aws_vpc.terraform_vpc.id
    cidr_block = var.pub2_cidr
    availability_zone = "eu-west-1c"
    tags = {
        Name = "${var.pub_subnet_name}-2"
    }
}
resource "aws_subnet" "terraform_private_subnet"{
    vpc_id = aws_vpc.terraform_vpc.id
    cidr_block = var.priv_cidr
    tags = {
        Name = var.priv_subnet_name
    }
}



# Associate route tables with subnets
resource "aws_route_table_association" "a1" {
  subnet_id = aws_subnet.terraform_public_subnet_1.id
  route_table_id = aws_vpc.terraform_vpc.default_route_table_id
}
resource "aws_route_table_association" "a2" {
  subnet_id = aws_subnet.terraform_public_subnet_2.id
  route_table_id = aws_vpc.terraform_vpc.default_route_table_id
}
resource "aws_route_table_association" "a3" {
  subnet_id = aws_subnet.terraform_private_subnet.id
  route_table_id = aws_route_table.terraform_rt_priv.id
}



# Create security groups, all rules must be separated because of a bug
resource "aws_security_group" "pub_sec_group" {
  name = var.pub_sec_name
  description = "Public security group"
  vpc_id = aws_vpc.terraform_vpc.id
}
resource "aws_security_group_rule" "http_access" {
  type = "ingress"
  from_port = "80"
  to_port = "80"
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.pub_sec_group.id
}
resource "aws_security_group_rule" "my_ssh" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = [var.my_ip]
  security_group_id = aws_security_group.pub_sec_group.id
}
resource "aws_security_group_rule" "vpc_access" {
  type = "ingress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = [var.vpc_cidr]
  security_group_id = aws_security_group.pub_sec_group.id
}
resource "aws_security_group_rule" "outbound_traffic" {
  type = "egress"
  from_port = "0"
  to_port = "0"
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.pub_sec_group.id
}

# Private security
resource "aws_security_group" "priv_sec_group" {
  name = var.priv_sec_name
  description = "Private security group"
  vpc_id = aws_vpc.terraform_vpc.id
}
resource "aws_security_group_rule" "priv_vpc_access" {
  type = "ingress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = [var.vpc_cidr]
  security_group_id = aws_security_group.priv_sec_group.id
}
resource "aws_security_group_rule" "priv_ssh_access" {
  type = "ingress"
  from_port = "22"
  to_port = "22"
  protocol = "tcp"
  cidr_blocks = [var.my_ip]
  security_group_id = aws_security_group.priv_sec_group.id
}
resource "aws_security_group_rule" "priv_vpc_outbound" {
  type = "egress"
  from_port = "0"
  to_port = "0"
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.priv_sec_group.id
}



# Create a target group
resource "aws_lb_target_group" "target_group" {
  name     = "eng84-ben-terraform-tg-1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraform_vpc.id
}



# Create an application load balancer
resource "aws_lb" "load_balancer" {
  name               = "eng84-ben-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.pub_sec_group.id]
  subnets            = [aws_subnet.terraform_public_subnet_1.id, aws_subnet.terraform_public_subnet_2.id]
  enable_deletion_protection = false
}



# Create a listener
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }

  depends_on = [aws_lb_target_group.target_group, aws_lb.load_balancer]
}



# Create an AMI template
resource "aws_launch_template" "launch_template" {
  name = "eng84_ben_terraform_template"
  ebs_optimized = false

  image_id = var.app_ami
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.pub_sec_group.id]
  }

  depends_on = [aws_security_group.pub_sec_group]
}



# Create an auto-scaling group
resource "aws_autoscaling_group" "auto_scale" {
  name = "eng84_ben_auto_scaling_group"
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1

  lifecycle {
    ignore_changes = [target_group_arns]
  }

  target_group_arns = [aws_lb_target_group.target_group.arn]

  vpc_zone_identifier = [aws_subnet.terraform_public_subnet_1.id, aws_subnet.terraform_public_subnet_2.id]

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }

  depends_on = [aws_launch_template.launch_template, aws_lb_listener.listener]
}



# Launching an EC2 using our db ami
# The resource keyword is used to create instances
# Resource type followed by name
resource "aws_instance" "terraform_db" {
  ami =  var.db_ami
  instance_type = "t2.micro"
  associate_public_ip_address = true
  key_name = var.key
  subnet_id = aws_subnet.terraform_private_subnet.id
  private_ip = var.db_ip
  vpc_security_group_ids = [aws_security_group.priv_sec_group.id]

  tags = {
      Name = var.db_name
  }
}