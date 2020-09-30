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
    user = "ec2user"
    private_key = file(var.PATH_TO_PRIVATE_KEY)
    host = self.public_ip
  }
  instance_type = "t2.medium"
  ami = "ami-098f16afa9edf40be"
  key_name = file(var.PATH_TO_PUBLIC_KEY)
  vpc_security_group_ids = [aws_security_group.autobox-sg.id]
  subnet_id = aws_subnet.autobox-01.id
  provisioner "remote-exec" {
    inline = [
      "sudo yum update",
      "sudo yum -y upgrade",
      "sudo yum -y install wget",
      "sudo systemctl enable --now firewalld",
      "sudo firewall-cmd --permanent --add-port=8000/tcp",
      "sudo firewall-cmd --permanent --add-port=8088/tcp",
      "sudo firewall-cmd --permanent --add-port=8089/tcp",
      "sudo firewall-cmd --permanent --add-port=9997/tcp",
      "sudo systemctl restart firewalld",
      "sudo useradd splunk -d /home/splunk",
      "sudo usermod -a -G root,wheel splunk",
      "sudo sed -i 's@PATH=$PATH:$HOME/.local/bin:$HOME/bin@PATH=$PATH:$HOME/.local/bin:$HOME/bin:/opt/splunk/bin@g' /home/splunk/.bash_profile",
      "sudo chown --recursive splunk:splunk /home/splunk/",
      "sudo wget -O splunk-8.0.6-152fb4b2bb96-Linux-x86_64.tgz 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=8.0.6&product=splunk&filename=splunk-8.0.6-152fb4b2bb96-Linux-x86_64.tgz&wget=true'",
      "sudo tar -zxvf splunk-8.0.6-152fb4b2bb96-Linux-x86_64.tgz -C /opt",
      "sudo touch /opt/splunk/etc/system/local/user-seed.conf",
      "sudo (echo '[user_info]' echo 'USERNAME = splunkadmin' echo 'PASSWORD = hialplissplunk')>/opt/splunk/etc/system/local/user-seed.conf",
      "sudo touch /opt/splunk/etc/splunk-launch.conf",
      "(echo 'SPLUNK_SERVER_NAME=Splunkd' echo 'SPLUNK_OS_USER=splunk' echo 'SPLUNK_HOME=/opt/splunkforwarder')>/opt/splunk/etc/splunk-launch.conf",
      "chown --recursive splunk:splunk /opt/splunk/",
      "sudo /opt/splunk/bin/./splunk start --answer-yes --accept-license",
      "sudo /opt/splunk/bin/./splunk enable boot-start -user splunk",
      "sudo /opt/splunk/bin/./splunk enable listen 9997",
      "sudo /opt/splunk/bin/./splunk start"
    ]
  }
    tags = {
      Name = "Autobox Splunk01"
  }
}