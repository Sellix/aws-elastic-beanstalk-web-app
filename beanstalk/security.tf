resource "aws_security_group" "sellix-eb-security-group" {
  name        = "${var.tags["Project"]}-security-group"
  description = "Autoscaling Traffic"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow EC2s Ingress HTTP Traffic"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.sellix-eb-elb-security-group.id]
  }
  ingress {
    description     = "Allow EC2s Ingress HTTPs Traffic"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.sellix-eb-elb-security-group.id]
  }
  ingress {
    description = "Allow EC2s Ingress SSM SSH Traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["127.0.0.1/32"]
  }
  egress {
    description      = "Allow EC2s Egress Traffic"
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = merge({
    "Name" = "${var.tags["Project"]}-security-group"
    },
    var.tags
  )
}

locals {
  elb_listening_ports = concat([80], local.is_ssl ? [443] : [])
}

data "cloudflare_ip_ranges" "cloudflare" {}

resource "aws_security_group" "sellix-eb-elb-security-group" {
  name        = "${var.tags["Project"]}-elb-security-group"
  description = "ELB traffic"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = local.elb_listening_ports

    content {
      description = "Allow ELB Ingress"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = var.cloudflare_enabled ? data.cloudflare_ip_ranges.cloudflare.ipv4_cidr_blocks : ["0.0.0.0/0"]
    }
  }

  dynamic "egress" {
    for_each = local.elb_listening_ports

    content {
      description = "Allow ELB Egress HTTP"
      from_port   = egress.value
      to_port     = egress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  tags = merge({
    "Name" = "${var.tags["Project"]}-elb-security-group"
    },
    var.tags
  )
}
