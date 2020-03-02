provider "aws" {
}

# Create a VPC
# resource "aws_vpc" "example" {
#   cidr_block = "10.0.0.0/16"
# }

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

resource "aws_instance" "jump" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"

  user_data = <<EOF
#!/usr/bin/bash

sudo apt install apache2
sudo service apache2 start

EOF

  tags = {
    Name = "tfm"
  }
}
