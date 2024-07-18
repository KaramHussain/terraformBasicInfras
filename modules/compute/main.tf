resource "aws_instance" "nginxServer" {
  ami           = var.ubuntu24_04
  instance_type = "t2.micro"
  network_interface {
    network_interface_id = var.NI_ID
    device_index         = 0
  }
  tags = {
      Name = "NginxServer"
  }
  user_data = base64encode(file("${path.module}/install_nginx.sh"))
}


# module "storage" {
#   source = "../storage"
#   nginx_server_id = aws_instance.nginxServer.id
# }