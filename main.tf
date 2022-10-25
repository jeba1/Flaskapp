provider "aws" {
    region = "us-east-2"
}
resource "aws_vpc" "dev" {
  cidr_block = "10.1.0.0/20"
  enable_dns_support = true
  enable_dns_hostnames = true

}
resource "aws_internet_gateway" "dev_gw" {
  vpc_id = aws_vpc.dev.id

  tags = {
    Name = "dev_gw"
  }
}

data "aws_availability_zones" "dev_az" {
  state = "available"
}
resource "aws_subnet" "public1" {
  vpc_id     = aws_vpc.dev.id
  cidr_block = "10.1.1.0/26"
  availability_zone = data.aws_availability_zones.dev_az.names[0]

  tags = {
    Name = "Public1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id     = aws_vpc.dev.id
  cidr_block = "10.1.2.0/26"
  availability_zone = data.aws_availability_zones.dev_az.names[1]

  tags = {
    Name = "Public2"
  }
}
resource "aws_route_table" "Public1_rt" {
  vpc_id = aws_vpc.dev.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_gw.id
  }
  tags = {
    Name = "Public1_rt"
  }
} 
resource "aws_route_table" "Public2_rt" {
  vpc_id = aws_vpc.dev.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_gw.id
  }
    tags = {
    Name = "Public2_rt"
  }
} 
resource "aws_route_table_association" "Public1_rt" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.Public1_rt.id
}

resource "aws_route_table_association" "public2_rt" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.Public2_rt.id
}
resource "aws_security_group" "instance_sg" {
  name        = "ec2_sg"
  description = "Allow TLS inbound traffic and ssh"
  vpc_id      = aws_vpc.dev.id


ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.dev.cidr_block]
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "instance_sg"
  }
  
}
resource "aws_security_group" "alb_sg" {
  name        = "allow_tls and ssh"
  description = "Allow TLS inbound traffic and ssh"
  vpc_id      = aws_vpc.dev.id
  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.dev.cidr_block]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "alb1_sg"
  }
  
}
resource "aws_instance" "ec2_host1" {
  ami           = "ami-089a545a9ed9893b6"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public1.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  user_data = file("data.sh")
  

  tags = {
    Name = "ec2_host1"
  }
}

resource "aws_instance" "ec2_host2" {
  ami           = "ami-089a545a9ed9893b6"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public2.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  user_data = file("data.sh")
  

  tags = {
    Name = "ec2_host2"
  }
}

resource "aws_lb" "dev_alb" {
  name               = "dev-python-flask"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]

  enable_cross_zone_load_balancing = true
  enable_deletion_protection = false

  

  tags = {
    Environment = "dev"
  }
}
resource "aws_lb_target_group" "dev_tg" {
  name     = "instance-tg"
  port     = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id   = aws_vpc.dev.id
}
resource "aws_lb_target_group_attachment" "dev_tg" {
  depends_on = [aws_instance.ec2_host1]  
  target_group_arn = aws_lb_target_group.dev_tg.arn
  target_id        = aws_instance.ec2_host1.id
  port             = 80
}

resource "aws_lb_listener" "dev_alb_listener" {
  load_balancer_arn = aws_lb.dev_alb.arn
  port              = "80"
  protocol          = "HTTP"
  

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dev_tg.arn
  }
}