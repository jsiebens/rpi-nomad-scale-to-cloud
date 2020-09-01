resource "aws_security_group" "vpn-inbound" {
  name        = "tf-vpn-inbound"
  description = "vpn-inbound"

  ingress {
    description = "udp"
    from_port   = 1
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["100.64.0.0/10"]
  }

  ingress {
    description = "tcp"
    from_port   = 1
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["100.64.0.0/10"]
  }

  tags = {
    Name = "vpc-inbound"
  }
}

resource "aws_security_group" "vpn-outbound" {
  name        = "tf-outbound-all"
  description = "outbound-all"

  egress {
    description      = "outgoing udp"
    from_port        = 1
    to_port          = 65535
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "outgoing tcp"
    from_port        = 1
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "outgoing icmp"
    from_port        = "8"
    to_port          = "0"
    protocol         = "icmp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow-all-outbound"
  }
}
