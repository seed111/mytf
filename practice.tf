# Configure the AWS Provider
provider "aws" {
  profile = "default"
  region  = "eu-north-1"
}

# Create a VPC
resource "aws_vpc" "myproject_vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "myproject_vpc"
  }
}

# Create a Subnet
resource "aws_subnet" "myproject_subnet" {
  vpc_id            = aws_vpc.myproject_vpc.id
  cidr_block        = "172.16.1.0/24"
  availability_zone = "eu-north-1a"

  tags = {
    Name = "myproject_subnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "myproject_ig" {
  vpc_id = aws_vpc.myproject_vpc.id

  tags = {
    Name = "myproject_internet"
  }
}

# Create a Route Table with Internet Gateway
resource "aws_route_table" "myproject_igw" {
  vpc_id = aws_vpc.myproject_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myproject_ig.id
  }

  tags = {
    Name = "myproject_igw"
  }
}

# Associate the Route Table with the Subnet
resource "aws_route_table_association" "public_1_rt_assoc" {
  subnet_id      = aws_subnet.myproject_subnet.id
  route_table_id = aws_route_table.myproject_igw.id
}

# Create a Security Group open to SSH and HTTP
resource "aws_security_group" "allow_http" {
  name        = "HTTP"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = aws_vpc.myproject_vpc.id

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
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Create an EC2 instance
resource "aws_instance" "app_server" {
  ami           = "ami-0c1ac8a41498c1a9c"
  instance_type = "t3.micro"

  subnet_id            = aws_subnet.myproject_subnet.id
  vpc_security_group_ids = [aws_security_group.allow_http.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install nginx -y
    echo "<h1>Hello from Terraform</h1>" > /var/www/html/index.html
    sudo systemctl start nginx
    sudo systemctl enable nginx
  EOF

  tags = {
    Name = "Myterraforminstance"
  }
}