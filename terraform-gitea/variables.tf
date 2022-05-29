variable "instance_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "Gitea-server"
}

variable "alb_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "Gitea-lb"
}
