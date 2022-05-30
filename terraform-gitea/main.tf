terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

# VPC and Subnet
# Connect the instance to default vpc and subnet
provider "aws" {
  profile = "default"
  region  = "ap-southeast-1"
}

# Providing a reference to our default VPC
resource "aws_default_vpc" "default_vpc" {
}

# Providing a reference to our default subnets
resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "ap-southeast-1a"
}
resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "ap-southeast-1b"
}

# Create AWS security group for EC2 Instance
resource "aws_security_group" "gitea" {
  name        = "gitea"
  description = "Allow ssh  inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}

# Gitea EC2 Instance
resource "aws_instance" "host" {
  ami                    = "ami-0bd6906508e74f692"
  instance_type          = "t2.micro"
  key_name               = "gitea-deploy"
  vpc_security_group_ids = ["${aws_security_group.gitea.id}"]
  user_data              = <<HEREDOC
  #!/bin/bash
  sudo yum update -y
  sudo amazon-linux-extras install docker
  sudo service docker start
  sudo usermod -a -G docker ec2-user
  sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
HEREDOC

  associate_public_ip_address = true

  # Running remote execution script
  connection {
    type        = "ssh"
    host        = aws_instance.host.public_ip
    user        = "ec2-user"
    private_key = file("gitea-deploy.pem")
    timeout     = "2m"
  }
  provisioner "remote-exec" {
    inline = [
      "mkdir ~/gitea",
    ]
  }
  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "~/gitea/docker-compose.yml"
  }
  provisioner "remote-exec" {
    inline = [
      "cd ~/gitea/",
      "/usr/local/bin/docker-compose up -d",
    ]
  }


  tags = {
    Name = var.instance_name
  }
}

# ALB Load Balancer
resource "aws_lb" "application_load_balancer" {
  name               = var.lb_name # Naming our load balancer
  internal           = false
  load_balancer_type = "application"
  # Referencing the security group
  security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
  subnets = [ # Referencing the default subnets
    "${aws_default_subnet.default_subnet_a.id}",
    "${aws_default_subnet.default_subnet_b.id}"
  ]
}

# Creating a security group for the load balancer:
resource "aws_security_group" "load_balancer_security_group" {
  ingress {
    from_port   = 443 # Allowing traffic in from port 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic in from all sources
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0             # Allowing any incoming port
    to_port     = 0             # Allowing any outgoing port
    protocol    = "-1"          # Allowing any outgoing protocol 
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}

resource "aws_lb_target_group" "target_group" {
  name     = "target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default_vpc.id # Referencing the default VPC
}

# HTTPS request handler
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn # Referencing our load balancer
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.ssl-arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn # Referencing our target group
  }
}

# Redirect any HTTP request to HTTPS
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn # Referencing our load balancer
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
