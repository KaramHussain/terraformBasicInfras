## Creating VPC

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}


## Creating Public Subnets

resource "aws_subnet" "public_subnets" {
 count             = length(var.public_subnet_cidrs)
 vpc_id            = aws_vpc.main.id
 cidr_block        = element(var.public_subnet_cidrs, count.index)
 availability_zone = element(var.azs, count.index)
 map_public_ip_on_launch = true
 tags = {
   Name = "Task1-VPC-Public-Subnet ${count.index + 1}"
 }
}

## Creating Private Subets

resource "aws_subnet" "private_subnets" {
 count             = length(var.private_subnet_cidrs)
 vpc_id            = aws_vpc.main.id
 cidr_block        = element(var.private_subnet_cidrs, count.index)
 availability_zone = element(var.azs, count.index)
 
 tags = {
   Name = "Task1-VPC-Private-Subnet ${count.index + 1}"
 }
}


## Creaitng Internet Gateway

resource "aws_internet_gateway" "gw" {
 vpc_id = aws_vpc.main.id
 
 tags = {
   Name = "Task1-VPC-IG"
 }
}


##  Creating Public Route Table

resource "aws_route_table" "public_rt" {
 vpc_id = aws_vpc.main.id
 
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.gw.id
 }
 
 tags = {
   Name = "Task1-VPC-Public-rtb"
 }
}


## Associating Public Route Table with Public Subnets

resource "aws_route_table_association" "public_subnet_asso" {
 count = length(var.public_subnet_cidrs)
 subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
 route_table_id = aws_route_table.public_rt.id
}


## Creating NateGateway
resource "aws_eip" "nat_gw" {
  vpc = true
  
  tags = {
    Name = "Task1-VPC-NAT-EIP"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_gw.id
  subnet_id     = element(aws_subnet.public_subnets[*].id, 0) # Creating the NAT Gateway in the first public subnet

  tags = {
    Name = "Task1-VPC-NAT-GW"
  }
}




## Creating Private Route Table

resource "aws_route_table" "private_rt" {
 vpc_id = aws_vpc.main.id
 
 route {
   cidr_block = "0.0.0.0/0"
   nat_gateway_id = aws_nat_gateway.nat_gw.id
 }
 
 tags = {
   Name = "Task1-VPC-private-rtb"
 }
}

## Associating Private Route Table with Private Subnets

resource "aws_route_table_association" "private_subnet_asso" {
 count = length(var.private_subnet_cidrs)
 subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
 route_table_id = aws_route_table.private_rt.id
}



## SECURITY GROUP:

resource "aws_security_group" "nginx_sg" {
vpc_id      = aws_vpc.main.id

# Inbound Rules
  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
# HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
# SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
# Outbound Rules
  # Internet access to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


## Public NACL 

resource "aws_network_acl" "public_nacl" {
  vpc_id = aws_vpc.main.id

  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "Task1-Public-NACL"
  }
}


## Associate the Public Subnet with Public NACL:

# resource "aws_network_acl_association" "public_subnet_association" {
#   count       = length(var.public_subnet_cidrs)
#   subnet_id   = element(aws_subnet.public_subnets[*].id, count.index)
#   network_acl_id = aws_network_acl.public_nacl.id
# }



## Private NACL

resource "aws_network_acl" "private_nacl" {
  vpc_id = aws_vpc.main.id

  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 8080
    to_port    = 8080
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 3306
    to_port    = 3306
  }

  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "Task1-Private-NACL"
  }
}

## Associating Private NACL with private Subnets

resource "aws_network_acl_association" "private_subnet_association" {
  count       = length(var.private_subnet_cidrs)
  subnet_id   = element(aws_subnet.private_subnets[*].id, count.index)
  network_acl_id = aws_network_acl.private_nacl.id
}

## nginx_server Network interface

resource "aws_network_interface" "nginx_server_NIC" {
  subnet_id       = element(aws_subnet.public_subnets[*].id, 0)
  private_ips     = ["10.0.1.10"] 
  security_groups = [aws_security_group.nginx_sg.id]
  tags = {
    Name = "Task1-VPC-Public-ENI-1"
  }

}