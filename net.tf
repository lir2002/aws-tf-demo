# Create VPC
resource "aws_vpc" "ethan_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "ethan_vpc"
  }
}

# Create 1st subnet in VPC in Available zone 2a
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.ethan_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet"
  }
}

# Create 2nd subnet in VPC in Available zone 2b
resource "aws_subnet" "public_subnet_az2" {
  vpc_id            = aws_vpc.ethan_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_az2"
  }
}
# Create 1st subnet in VPC in Available zone 2a
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.ethan_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = false

  tags = {
    Name = "private_subnet"
  }
}

# Create 2nd subnet in VPC in Available zone 2b
resource "aws_subnet" "private_subnet_az2" {
  vpc_id            = aws_vpc.ethan_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = false

  tags = {
    Name = "private_subnet_az2"
  }
}

# Subnet group for database
resource "aws_db_subnet_group" "db_sbntg" {
  name       = "main"
  subnet_ids = [aws_subnet.private_subnet.id, aws_subnet.private_subnet_az2.id]

  tags = {
    Name = "Ethan DB subnet group"
  }
}

# Create security group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Allow HTTP/TLS inbound traffic and all outbound traffic to target group"
  vpc_id      = aws_vpc.ethan_vpc.id

  tags = {
    Name = "alb_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "to_traget_group" {
  security_group_id = aws_security_group.alb_sg.id
  referenced_security_group_id = aws_security_group.tg_sg.id
  from_port = 80
  to_port = 80
  ip_protocol = "tcp"
}
# Egress to internet to install software
resource "aws_vpc_security_group_egress_rule" "to_internet" {
  security_group_id = aws_security_group.tg_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol = -1
}
# Create security group for target group instance
resource "aws_security_group" "tg_sg" {
  name = "tg_sg"
  description = "Allow inboud from ALB"
  vpc_id = aws_vpc.ethan_vpc.id

  tags = {
    Name = "tg_sg"
  }
}
# Security group for Database
resource "aws_security_group" "db_sg" {
  name = "db_sg"
  description = "Allow only connection from Web server"
  vpc_id = aws_vpc.ethan_vpc.id

  tags = {
    Name = "db_sg"
  }

  ingress  {
    security_groups = [aws_security_group.tg_sg.id]
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    description = "Allow web server connect to Mysql port"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_internal_http" {
  security_group_id = aws_security_group.tg_sg.id
  referenced_security_group_id = aws_security_group.alb_sg.id
  from_port = 80
  ip_protocol = "tcp"
  to_port = 80
}

# for ssh debug troubleshoooot
resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.tg_sg.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 22
  ip_protocol = "tcp"
  to_port = 22
}

# Internet Gateway 
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.ethan_vpc.id
  tags = {
    Name = "igw-alb"
  }
}

# Route table
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.ethan_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.ethan_vpc.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }
}


resource "aws_main_route_table_association" "main_route_assoc" {
  vpc_id = aws_vpc.ethan_vpc.id
  route_table_id = aws_route_table.main_route_table.id
}