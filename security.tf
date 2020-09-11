resource "aws_security_group" "web-app-security-group" {
  name        = "sellix-web-app-security-group"
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
}