
provider "aws" {
  region  = "us-east-1"
  version = "~> 2.58"
}

resource "aws_default_vpc" "default" {
  tage = {
    Name = "Default VPC"
  }
}

data "aws_subnet_ids" "default_subnets" {
  vpc_id = "aws_default_vpc.default.id"
}

data "aws_ami" "aws-linux-2-latest" {
  most_recent = true
  owners = ["amazon"]
  filter{
  name   = "name"
  values = ["amzn2-ami-hvm-*"]
  }
}
data "aws_ami_ids" "aws-linux-2-latest_ids" {
   owners = ["amazon"]
}

resource "aws_security_group" "http_server_sg" {
  name = "http_server_sg"
  #vpc_id = "vpc-e9a5a793"
  vpc_id = "aws_default_vpc.default.id"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name = "http_server_sg"
  }
}

resource "aws_instance" "http_server" {
  ami                    = "ami-0323c3dd2da7fb37d"
  key_name               = "default-ec2"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.http_server_sg.id]
  #subnet_id              = "subnet-f27e8894"
  subnet_id = tolist(data.aws_subnet_ids.default_subnets.ids)[0]

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.aws_key_pair)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd -y",
      "sudo service httpd start",
      "echo Welcome to in28minutes - Virtual Server is at ${self.public_dns} | sudo tee /var/www/html/index.html"
    ]
  }
}