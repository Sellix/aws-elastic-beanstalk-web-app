resource "aws_security_group" "sellix-web-app-security-group" {
  name        = "${local.tags["Project"]}-security-group"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.sellix-web-app-vpc.id
  ingress {
    description = "allow vpc ingress traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [var.main_cidr_block]
  }
  egress {
    description = "allow vpc egress traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"] # rlly needed?
  }
  tags = merge({
    "Name" = "${local.tags["Project"]}-security-group"
    },
    local.tags
  )
}

resource "aws_security_group" "sellix-web-app-elb-security-group" {
  name        = "${local.tags["Project"]}-elb-security-group"
  description = "Allow ELB inbound traffic"
  vpc_id      = aws_vpc.sellix-web-app-vpc.id
  ingress {
    description = "ingress HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ingress HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "egress HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "egress HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge({
    "Name" = "${local.tags["Project"]}-elb-security-group"
    },
    local.tags
  )
}