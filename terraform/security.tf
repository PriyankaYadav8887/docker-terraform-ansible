
variable "my_ip_cidr" {
  description = "Your public IPv4 address in CIDR notation, for example x.x.x.x/32"
  type        = string
}

resource "aws_security_group" "web_sg" {
  name        = "docker-ansible-web-sg"
  description = "Allow SSH and application traffic from my IP"
  vpc_id      = aws_vpc.project_vpc.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    description = "Node.js app from my IP"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "docker-ansible-web-sg"
  }
}
