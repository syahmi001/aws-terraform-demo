output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.host.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.host.public_ip
}

output "amazon_domain" {
  value = aws_instance.host.public_dns
}

output "subnet" {
  value = aws_subnet.public.id
}
output "id" {
  value = aws_vpc.this.id
}
