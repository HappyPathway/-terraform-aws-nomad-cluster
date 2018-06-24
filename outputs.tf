output "nomad_security_group" {
  value = "${aws_security_group.nomad-cluster.id}"
}
