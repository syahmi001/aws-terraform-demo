variable "instance_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "Gitea-server"
}

variable "lb_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "Gitea-lb"
}

variable "ssl-arn" {
  description = "Value of the SSL certificate"
  type        = string
  default     = "arn:aws:acm:ap-southeast-1:707566046333:certificate/7649bf4d-059b-4bf3-bfdb-2867e6203eff"
}
