resource "aws_security_group" "sellix-eb-fuck-nat-security-group" {
  count       = (var.is_production && var.is_nat_instance) ? 1 : 0
  name        = "${var.tags["Project"]}-fuck-nat-security-group"
  description = "Managed Nat Instance Security Group"
  vpc_id      = aws_vpc.sellix-eb-vpc.id
  ingress {
    description = "accept vpc incoming (transit) traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [var.main_cidr_block]
  }
  egress {
    description = "allow private subnets to reach the web"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge({
    "Name" = "${var.tags["Project"]}-fuck-nat-security-group"
  })
}

resource "aws_security_group_rule" "sellix-eb-legacy-vpc-peering-security-group" {
  count             = (var.is_production && local.is_peering) ? 1 : 0
  description       = "Allow HTTPs Incoming traffic to legacy-vpc (APIs)"
  security_group_id = var.legacy-vpc-sg
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.main_cidr_block]
}