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

# Private key for SSH
# resource "tls_private_key" "key" {
#   algorithm   = "RSA"
#   ecdsa_curve = "P256"
# }
# resource "aws_key_pair" "key" {
#   public_key = tls_private_key.key.public_key_openssh
# }

# Gitea EC2 Instance
resource "aws_instance" "host" {
  ami                         = "ami-0bd6906508e74f692"
  instance_type               = "t2.micro"
  key_name                    = "gitea-deploy"
  user_data                   = <<HEREDOC
  #!/bin/bash
  sudo yum update -y
  sudo amazon-linux-extras install docker
  sudo service docker start
  sudo usermod -a -G docker ec2-user
  sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
HEREDOC
  associate_public_ip_address = true
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
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

  # connection {
  #   host        = aws_instance.host.public_ip
  #   type        = "ssh"
  #   user        = "ec2-user"
  #   private_key = "gitea-deploy"
  #   timeout     = "2m"
  # }

  tags = {
    Name = var.instance_name
  }
}

# ALB Load Balancer
resource "aws_alb" "application_load_balancer" {
  name               = var.alb_name # Naming our load balancer
  load_balancer_type = "application"
  subnets = [ # Referencing the default subnets
    "${aws_default_subnet.default_subnet_a.id}",
    "${aws_default_subnet.default_subnet_b.id}"
  ]
  # Referencing the security group
  security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
}

# Creating a security group for the load balancer:
resource "aws_security_group" "load_balancer_security_group" {
  ingress {
    from_port   = 3000 # Allowing traffic in from port 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic in from all sources
  }

  egress {
    from_port   = 0             # Allowing any incoming port
    to_port     = 0             # Allowing any outgoing port
    protocol    = "-1"          # Allowing any outgoing protocol 
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}

resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  port        = 3000
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_default_vpc.default_vpc.id # Referencing the default VPC
  health_check {
    matcher = "200,301,302"
    path    = "/"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.application_load_balancer.arn # Referencing our load balancer
  port              = "3000"
  protocol          = "HTTPS"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn # Referencing our target group
  }
}
