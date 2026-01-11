terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}
provider "aws" { region = var.aws_region }

variable "aws_region" { 
type = string
 default = "us-east-1" 
 }                 
variable "resource_prefix" {
 type = string
  default = "Shivansh-Chaurasia" 
  }    
variable "key_name" { 
 type = string
  default = "Shivansh_keypair" 
  }         

data "aws_availability_zones" "available" {}


resource "aws_vpc" "vpc" {
  cidr_block = "10.20.0.0/16"
  tags = { Name = "${var.resource_prefix}_vpc_q3" }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.20.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = { 
  Name = "${var.resource_prefix}_public_a_q3" 
  }
}
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.20.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]
  tags = { Name = "${var.resource_prefix}_public_b_q3" }
}
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.20.101.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = { Name = "${var.resource_prefix}_private_a_q3" }
}
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.20.102.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = { Name = "${var.resource_prefix}_private_b_q3" }
}


resource "aws_internet_gateway" "igw" { vpc_id = aws_vpc.vpc.id }
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  route { 
  cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.igw.id 
   }
}
resource "aws_route_table_association" "pub_a" { 
subnet_id = aws_subnet.public_a.id
 route_table_id = aws_route_table.public_rt.id 
 }
resource "aws_route_table_association" "pub_b" { 
subnet_id = aws_subnet.public_b.id
 route_table_id = aws_route_table.public_rt.id 
 }


resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" { 
allocation_id = aws_eip.nat.id
 subnet_id = aws_subnet.public_a.id 
 }

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id
  route { 
  cidr_block = "0.0.0.0/0"
   nat_gateway_id = aws_nat_gateway.nat.id
    }
}
resource "aws_route_table_association" "priv_a" { 
subnet_id = aws_subnet.private_a.id 
route_table_id = aws_route_table.private_rt.id 
}
resource "aws_route_table_association" "priv_b" { 
subnet_id = aws_subnet.private_b.id 
route_table_id = aws_route_table.private_rt.id 
}

# Security groups
resource "aws_security_group" "alb_sg" {
  name   = "${var.resource_prefix}_alb_sg_q3"
  vpc_id = aws_vpc.vpc.id
  ingress {
   from_port=80
    to_port=80
     protocol="tcp"
    cidr_blocks=["0.0.0.0/0"] 
    }
  egress  {
   from_port=0
    to_port=0
    protocol="-1"
     cidr_blocks=["0.0.0.0/0"]
      }
}

resource "aws_security_group" "app_sg" {
  name   = "${var.resource_prefix}_app_sg_q3"
  vpc_id = aws_vpc.vpc.id
  ingress {
    description = "Allow ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress {
   from_port=0
    to_port=0
     protocol="-1"
      cidr_blocks=["0.0.0.0/0"] 
      }
}


resource "aws_lb" "alb" {
  name               = "${var.resource_prefix}-alb-q3"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "tg" {
  name     = "${var.resource_prefix}-tg-q3"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
  health_check { 
  path = "/"
   protocol = "HTTP"
    matcher = "200-399" 
    }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action { 
  type = "forward"
   target_group_arn = aws_lb_target_group.tg.arn 
   }
}


data "aws_ami" "amazon_linux" {
  owners      = ["137112412989"]
  most_recent = true
  filter { 
  name = "name"
   values = ["amzn2-ami-hvm-*-x86_64-gp2"] 
   }
}

resource "aws_launch_template" "lt" {
  name_prefix   = "${var.resource_prefix}_lt_q3"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name      = "Shivansh_keypair" 

  network_interfaces {
    associate_public_ip_address = false
    security_groups = [aws_security_group.app_sg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install -y nginx1
              systemctl enable nginx
              cat > /usr/share/nginx/html/index.html <<'HTML'
              <!doctype html><html><body><h1>${var.resource_prefix} - ASG Instance</h1></body></html>
              HTML
              systemctl start nginx
              EOF
  )
}

# ASG
resource "aws_autoscaling_group" "asg" {
  name                      = "${var.resource_prefix}_asg_q3"
  max_size                  = 2
  min_size                  = 1
  desired_capacity          = 1
  vpc_zone_identifier       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.tg.arn]
  health_check_type = "ELB"
  tag {
    key                 = "Name"
    value               = "${var.resource_prefix}_asg_instance_q3"
    propagate_at_launch = true
  }
}

output "alb_dns_name" { value = aws_lb.alb.dns_name }
