provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.11.0.0/16"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.11.1.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "private"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.11.2.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name = "public"
  }
}

resource "aws_eip" "nat_gateway_ip" {
  vpc        = true
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_nat_gateway" "nat_gateway" {

  allocation_id = aws_eip.nat_gateway_ip.id
  subnet_id     = aws_subnet.public_subnet.id

}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name = "private"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "public"
  }
}

resource "aws_route_table_association" "public_route_table_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_route_table_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}


resource "aws_key_pair" "amanu_personal" {
  key_name   = "amanu-personal"
  public_key = file("~/.ssh/id_rsa.pub")
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "ssh_enabled" {
  name        = "allow_ssh"
  description = "Allows SSH connection from anwhere"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "jump" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.amanu_personal.key_name

  subnet_id       = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.ssh_enabled.id]

  tags = {
    Name = "jump"
  }
}

resource "aws_eip" "jump_ip" {
  vpc        = true
  instance   = aws_instance.jump.id
  depends_on = [aws_internet_gateway.gw]
}


output "ec2_address" {
  value = aws_instance.jump.public_ip
}

output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "nat_ip" {
  value = aws_eip.nat_gateway_ip
}

output "jump_ip" {
  value = aws_eip.jump_ip
}

