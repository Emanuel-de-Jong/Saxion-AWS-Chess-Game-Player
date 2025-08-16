terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  shared_credentials_files = ["$HOME/.aws/credentials"]
  region                   = "us-east-1"
}

resource "aws_key_pair" "chess_kp" {
  key_name   = "chess_kp"
  public_key = file("id_rsa.pub")

  tags = {
    Name = "chess_kp"
  }
}

resource "aws_vpc" "chess_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "chess_vpc"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.chess_vpc.id
  cidr_block              = element(var.public_subnet_cidrs, 0)
  availability_zone       = element(var.azs, 0)
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.chess_vpc.id
  cidr_block              = element(var.public_subnet_cidrs, 1)
  availability_zone       = element(var.azs, 1)
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet"
  }
}


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.chess_vpc.id

  tags = {
    Name = "gw"
  }
}

resource "aws_route_table" "rt_1" {
  vpc_id = aws_vpc.chess_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "rt"
  }
}

resource "aws_route_table" "rt_2" {
  vpc_id = aws_vpc.chess_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "rt"
  }
}

resource "aws_route_table_association" "rt_subnet_asso_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.rt_1.id
}

resource "aws_route_table_association" "rt_subnet_asso_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.rt_2.id
}

resource "aws_security_group" "sg_ec2_b_1" {
  name        = "sg_ec2_b_1"
  vpc_id      = aws_vpc.chess_vpc.id
  description = "sg_ec2_b_1"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = [element(var.public_subnet_cidrs, 0)]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_ec2_b"
  }
}

resource "aws_security_group" "sg_ec2_b_2" {
  name        = "sg_ec2_b_2"
  vpc_id      = aws_vpc.chess_vpc.id
  description = "sg_ec2_b_2"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = [element(var.public_subnet_cidrs, 1)]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_ec2_b"
  }
}

resource "aws_security_group" "sg_ec2_db" {
  name        = "sg_ec2_db"
  vpc_id      = aws_vpc.chess_vpc.id
  description = "sg_ec2_db"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.ec2_b_1.public_ip}/32", "${aws_instance.ec2_b_2.public_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_ec2_db"
  }
}

resource "aws_security_group" "sg_ec2_f" {
  name        = "sg_ec2_f"
  vpc_id      = aws_vpc.chess_vpc.id
  description = "sg_ec2_f"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_ec2_f"
  }
}

resource "aws_security_group" "sg_lb" {
  name        = "sg_lb"
  vpc_id      = aws_vpc.chess_vpc.id
  description = "sg_lb"

  ingress {
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_lb"
  }
}

data "aws_ami" "ami_ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_network_interface" "ni_b_1" {
  subnet_id       = aws_subnet.public_subnet_1.id
  security_groups = [aws_security_group.sg_ec2_b_1.id]

  tags = {
    Name = "ni_b"
  }
}

resource "aws_network_interface" "ni_b_2" {
  subnet_id       = aws_subnet.public_subnet_2.id
  security_groups = [aws_security_group.sg_ec2_b_2.id]

  tags = {
    Name = "ni_b"
  }
}

resource "aws_network_interface" "ni_db" {
  subnet_id       = aws_subnet.public_subnet_1.id
  security_groups = [aws_security_group.sg_ec2_db.id]

  tags = {
    Name = "ni_db"
  }
}

resource "aws_network_interface" "ni_f" {
  subnet_id       = aws_subnet.public_subnet_1.id
  security_groups = [aws_security_group.sg_ec2_f.id]

  tags = {
    Name = "ni_f"
  }
}

resource "aws_instance" "ec2_b_1" {
  ami           = data.aws_ami.ami_ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.chess_kp.key_name
  user_data     = file("backend/user_data_b.sh")

  provisioner "file" {
    source      = "backend/docker-compose.yml"
    destination = "/home/ubuntu/docker-compose.yml"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("id_rsa")
      host        = self.public_ip
    }
  }

  provisioner "file" {
    source      = "../dockerize.sh"
    destination = "/home/ubuntu/dockerize.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("id_rsa")
      host        = self.public_ip
    }
  }

  network_interface {
    network_interface_id = aws_network_interface.ni_b_1.id
    device_index         = 0
  }

  tags = {
    Name = "ec2_b"
  }
}

resource "aws_instance" "ec2_b_2" {
  ami           = data.aws_ami.ami_ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.chess_kp.key_name
  user_data     = file("backend/user_data_b.sh")

  provisioner "file" {
    source      = "backend/docker-compose.yml"
    destination = "/home/ubuntu/docker-compose.yml"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("id_rsa")
      host        = self.public_ip
    }
  }

  provisioner "file" {
    source      = "../dockerize.sh"
    destination = "/home/ubuntu/dockerize.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("id_rsa")
      host        = self.public_ip
    }
  }

  network_interface {
    network_interface_id = aws_network_interface.ni_b_2.id
    device_index         = 0
  }

  tags = {
    Name = "ec2_b"
  }
}

resource "aws_instance" "ec2_db" {
  ami           = data.aws_ami.ami_ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.chess_kp.key_name
  user_data     = file("database/user_data_db.sh")

  provisioner "file" {
    source      = "database/docker-compose.yml"
    destination = "/home/ubuntu/docker-compose.yml"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("id_rsa")
      host        = self.public_ip
    }
  }

  network_interface {
    network_interface_id = aws_network_interface.ni_db.id
    device_index         = 0
  }

  tags = {
    Name = "ec2_db"
  }
}

resource "aws_instance" "ec2_f" {
  ami           = data.aws_ami.ami_ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.chess_kp.key_name
  user_data     = file("frontend/user_data_f.sh")

  provisioner "file" {
    source      = "../frontend/dist/"
    destination = "/home/ubuntu/"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("id_rsa")
      host        = self.public_ip
    }
  }

  network_interface {
    network_interface_id = aws_network_interface.ni_f.id
    device_index         = 0
  }

  tags = {
    Name = "ec2_f"
  }
}

resource "aws_lb" "lb" {
  name               = "lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_lb.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name = "lb"
  }
}

resource "aws_lb_target_group" "lb_tg" {
  name     = "tg"
  port     = 5001
  protocol = "HTTP"
  vpc_id   = aws_vpc.chess_vpc.id

  tags = {
    Name = "lb_tg"
  }
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "5001"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg.arn
  }

  tags = {
    Name = "lb_listener"
  }
}

resource "aws_lb_target_group_attachment" "lb_tg_attachment_ec2_b_1" {
  target_group_arn = aws_lb_target_group.lb_tg.arn
  target_id        = aws_instance.ec2_b_1.id
  port             = 5001
}

resource "aws_lb_target_group_attachment" "lb_tg_attachment_ec2_b_2" {
  target_group_arn = aws_lb_target_group.lb_tg.arn
  target_id        = aws_instance.ec2_b_2.id
  port             = 5001
}
