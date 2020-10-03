terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
provider "aws" {
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
  region = "us-east-1"
}
resource "aws_vpc" "autobox" {
  cidr_block = "10.0.0.0/18"
}
resource "aws_internet_gateway" "autobox" {
  vpc_id = aws_vpc.autobox.id
}
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.autobox.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.autobox.id
}
resource "aws_subnet" "autobox-01" {
  vpc_id     = aws_vpc.autobox.id
  cidr_block = "10.0.1.0/28"
  map_public_ip_on_launch = true
  tags = {
    Name = "Autobox 01"
  }
}
resource "aws_security_group" "autobox-sg" {
  vpc_id       = aws_vpc.autobox.id
  name         = "Autobox Security Group"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # splunk forwarders
  ingress {
    from_port   = 9997
    to_port     = 9997
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # splunk web
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #deployment server
    ingress {
    from_port   = 8089
    to_port     = 8089
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "autobox-splunk01" {
  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = file(var.PATH_TO_PRIVATE_KEY)
    host = self.public_ip
  }
  instance_type = "t2.medium"
  ami = "ami-098f16afa9edf40be"
  key_name = "autobox-key"
  vpc_security_group_ids = [aws_security_group.autobox-sg.id]
  subnet_id = aws_subnet.autobox-01.id
  provisioner "remote-exec" {
    inline = [
      "sudo yum -y update",
      "sudo yum -y upgrade",
      "sudo yum -y install wget",
      "sudo useradd splunk -d /home/splunk",
      "sudo usermod -a -G root,wheel splunk",
      "sudo echo 'PATH=$PATH:$HOME/.local/bin:$HOME/bin:/opt/splunk/bin' >> /home/splunk/.bash_profile",
      "sudo chown --recursive splunk:splunk /home/splunk/",
      "sudo wget -O splunk-8.0.6-152fb4b2bb96-Linux-x86_64.tgz 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=8.0.6&product=splunk&filename=splunk-8.0.6-152fb4b2bb96-Linux-x86_64.tgz&wget=true'",
      "sudo tar -zxvf splunk-8.0.6-152fb4b2bb96-Linux-x86_64.tgz -C /opt",
      "sudo touch /opt/splunk/etc/system/local/user-seed.conf",
      "sudo echo '[user_info]' >> /opt/splunk/etc/system/local/user-seed.conf",
      "sudo echo 'USERNAME = splunkadmin' >> /opt/splunk/etc/system/local/user-seed.conf",
      "sudo echo 'PASSWORD = ' >> /opt/splunk/etc/system/local/user-seed.conf",
      "sudo touch /opt/splunk/etc/splunk-launch.conf",
      "sudo echo 'SPLUNK_SERVER_NAME=Splunkd' >> /opt/splunk/etc/splunk-launch.conf",
      "sudo echo 'SPLUNK_OS_USER=splunk' >> /opt/splunk/etc/splunk-launch.conf",
      "sudo echo 'SPLUNK_HOME=/opt/splunk' >> /opt/splunk/etc/splunk-launch.conf"
    ]
  }
    tags = {
      Name = "Autobox Splunk01"
  }
}