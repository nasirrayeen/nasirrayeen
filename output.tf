output "aws_ami_id" {
  value = data.aws_ami.latest_amzon_linux_ami.id
}

output "aws_publib_ip" {
  value = aws_instance.myapp-server.public_ip
}