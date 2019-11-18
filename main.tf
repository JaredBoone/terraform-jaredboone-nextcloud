provider "aws" {
  profile    = "${var.aws_profile}"
  region     = "${var.aws_region}"
  version    = "~> 1.7"
}

variable "ssh_key_name" {}

variable "aws_profile" {}

variable "aws_region" {}

resource "aws_kms_key" "this" {
}

resource "aws_security_group" "default" {
  name = "Default Security Group"
  description = "Allows all outbound traffic"

  egress {
    description = "Outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    AppName = "nextcloud"
    Environment = "${terraform.workspace}"
    Terraform = "yes"
  }
}

resource "aws_security_group" "ssh" {
  name = "SSH Security Group"
  description = "Allow remote SSH access"

  ingress {
    description = "Limited SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    AppName = "nextcloud"
    Environment = "${terraform.workspace}"
    Terraform = "yes"
  }
}

resource "aws_security_group" "http" {
  name = "HTTP/S Security Group"
  description = "Allows remote access to HTTP & HTTPS"

  ingress {
    description = "HTTP Port"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS Port"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    AppName = "nextcloud"
    Environment = "${terraform.workspace}"
    Terraform = "yes"
  }
}


resource "aws_security_group" "postgres" {
  name = "Postgres Security Group"
  description = "Allow remote Postgres access"

  ingress {
    description = "Limited Postgres access"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    AppName = "nextcloud"
    Environment = "${terraform.workspace}"
    Terraform = "yes"
  }
}

resource "aws_eip" "this" {
  vpc      = true
  instance = "${aws_instance.nextcloud_ec2.id}"
}

data "aws_ami" "centos_linux" {
  owners      = ["679593333241"]
  most_recent = true

  filter {
      name   = "name"
      values = ["CentOS Linux 7 x86_64 HVM EBS *"]
  }

  filter {
      name   = "architecture"
      values = ["x86_64"]
  }

  filter {
      name   = "root-device-type"
      values = ["ebs"]
  }
}

resource "aws_instance" "nextcloud_ec2" {
  ami           = "${data.aws_ami.centos_linux.id}"
  instance_type = "t2.micro"
  associate_public_ip_address = true

  key_name = "${var.ssh_key_name}"

  vpc_security_group_ids = ["${aws_security_group.default.id}", "${aws_security_group.ssh.id}", "${aws_security_group.postgres.id}", "${aws_security_group.http.id}"]

  root_block_device {
    volume_size = 64
    delete_on_termination = true
  }

  ebs_block_device{
    device_name = "/dev/sdf"
    volume_size = 50
    delete_on_termination = false
  }
}



