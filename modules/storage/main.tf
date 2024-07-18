resource "aws_ebs_volume" "nginx_server_ebs" {
  availability_zone = var.ebs_az  // Specify the availability zone where your EC2 instance resides
  size              = 20  // Size of the volume in GiB
  tags = {
    Name = "nginx_ebs_storage"
  }
  type = "gp2"
}

resource "aws_volume_attachment" "nginx_server_ebsAttach" {
    device_name = "/dev/sdh"
    volume_id = aws_ebs_volume.nginx_server_ebs.id
    instance_id = var.nginx_server_id
}
