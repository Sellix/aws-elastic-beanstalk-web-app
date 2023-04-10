resource "aws_security_group" "sellix-eb-security-group" {
  name        = "${var.tags["Project"]}-security-group"
  description = "Autoscaling Traffic"
  vpc_id      = var.vpc_id
  ingress {
    description = "Allow EC2s Ingress HTTP Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.main_cidr_block]
  }
  ingress {
    description = "Allow EC2s Ingress HTTPs Traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.main_cidr_block]
  }
  ingress {
    description = "Allow EC2s Ingress SSM SSH Traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["127.0.0.1/32"]
  }
  egress {
    description = "Allow EC2s Egress Traffic"
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

resource "aws_security_group" "sellix-eb-elb-security-group" {
  name        = "${var.tags["Project"]}-elb-security-group"
  description = "ELB traffic"
  vpc_id      = var.vpc_id
  ingress {
    description = "Allow ELB Ingress HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow ELB Ingress HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow ELB Egress HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow ELB Egress HTTPs"
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
