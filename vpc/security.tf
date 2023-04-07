resource "aws_security_group" "sellix-eb-security-group" {
  name        = "${var.tags["Project"]}-security-group"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.sellix-eb-vpc.id
  ingress {
    description = "allow vpc ingress traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [var.main_cidr_block]
  }
  egress {
    description = "allow egress traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge({
    "Name" = "${var.tags["Project"]}-security-group"
    },
    var.tags
  )
}

resource "aws_security_group_rule" "sellix-eb-vpc-peering-security-group-rule" {
  count             = var.is_production ? 1 : 0
  security_group_id = aws_security_group.sellix-eb-security-group.id
  description       = "allow legacy vpc ingress traffic"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = [var.legacy-vpc_cidr-block]
}

resource "aws_security_group" "sellix-eb-elb-security-group" {
  name        = "${var.tags["Project"]}-elb-security-group"
  description = "Allow ELB inbound traffic"
  vpc_id      = aws_vpc.sellix-eb-vpc.id
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
    "Name" = "${var.tags["Project"]}-elb-security-group"
    },
    var.tags
  )
}
