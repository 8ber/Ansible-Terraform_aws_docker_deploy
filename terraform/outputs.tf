output "server-ip" {
    value = aws_instance.app-server.public_ip
}

output "ami_id" {
  value = data.aws_ami.amazon-linux-image.id
}