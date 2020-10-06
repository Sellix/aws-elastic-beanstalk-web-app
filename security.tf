resource "aws_security_group" "web-app-security-group" {
  name        = "sellix-web-app-${var.environment_check}-security-group"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.web-app-vpc.id
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = -1
    cidr_blocks     = [var.main_cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags
}

resource "aws_security_group" "web-app-elb-security-group" {
  name        = "sellix-web-app-${var.environment_check}-elb-security-group"
  description = "Allow ELB inbound traffic"
  vpc_id      = aws_vpc.web-app-vpc.id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags
}