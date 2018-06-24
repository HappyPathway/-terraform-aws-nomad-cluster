resource "aws_security_group" "nomad" {
  name        = "nomad"
  description = "Nomad Cluster"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_security_group_rule" "nomad-ssh" {
  security_group_id = "${aws_security_group.nomad.id}"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

// This rule allows Vault HTTP API access to individual nodes, since each will
// need to be addressed individually for unsealing.
resource "aws_security_group_rule" "nomad-cluster" {
  security_group_id = "${aws_security_group.nomad.id}"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  self              = true
}

resource "aws_security_group_rule" "nomad-egress" {
  security_group_id = "${aws_security_group.nomad.id}"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
