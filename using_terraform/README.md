# Auto Scaling and Load Balancing using AWS Console

## Auto Scaling Group & load balancer


### Basic Setup
1. First we create a VPC with an internet gateway.
    ```
    # Use the keyword "provider" to define what cloud service we will use:
    provider "aws" {
        region = "eu-west-1"
    }
    # Create an internet gateway that attaches to our vpc
    resource "aws_internet_gateway" "terraform_igw" {
      vpc_id = aws_vpc.terraform_vpc.id
    
      tags = {
        Name = var.igw_name
      }
    }
    ```


2. Now we create route tables, one public and one private.
    ```
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
    ```


3. Its time to create 3 subnets, 2 public and one private. We need 2 for multiple az.
    ```
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
    ```
   

4. Of course, we must also associate these subnets with their route tables.
    ```
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
    ```


5. Next we have to create our security groups for use later, it's important to create the rules separately.
    ```
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
    ```
   

### Load Balancer
1. The first thing we have to do is create an empty target group, this will be managed automatically.
    ```
    # Create a target group
    resource "aws_lb_target_group" "target_group" {
      name     = "eng84-ben-terraform-tg-1"
      port     = 80
      protocol = "HTTP"
      vpc_id   = aws_vpc.terraform_vpc.id
    }
    ```
   

2. Next we have to create an internet facing application load balancer.
    ```
    # Create an application load balancer
    resource "aws_lb" "load_balancer" {
      name               = "eng84-ben-load-balancer"
      internal           = false
      load_balancer_type = "application"
      security_groups    = [aws_security_group.pub_sec_group.id]
      subnets            = [aws_subnet.terraform_public_subnet_1.id, aws_subnet.terraform_public_subnet_2.id]
      enable_deletion_protection = false
    }
    ```
   

3. Now we have to create a listener that will forward traffic from our load balancer to our target group.
    ```
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
    ```
   

### Auto Scaling Group
1. First we have to create a launch template based on an AMI.
    ```
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
    ```


2. Now it's just as simple as creating the auto-scaling group itself.
    ```
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
    ```


### Launching a db instance manually
1. This works exactly the same as in my previous guide.
    ```
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
    ```
