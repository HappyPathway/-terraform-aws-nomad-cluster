output "nomad_security_group" {
  value = "${aws_security_group_rule.nomad-cluster.id}"
}
