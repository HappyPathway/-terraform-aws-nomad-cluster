resource "template_file" "install-server" {
  template = "${file("${path.module}/scripts/install.sh.tpl")}"

  vars {
    consul_cluster   = "${var.consul_cluster}"
    vault_cluster    = "${var.vault_cluster}"
    vault_token      = "${var.vault_token}"
    nomad_server     = "true"
    nomad_client     = "false"
    nomad_datacenter = "${lookup(var.resource_tags, "ClusterName")}"
    servers          = "${var.servers}"
  }
}

data "aws_ami" "nomad_server_ami" {
  most_recent = true
  owners      = ["753646501470"]

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "tag:service_name"
    values = ["${var.service_name}"]
  }

  filter {
    name   = "tag:service_version"
    values = ["${var.service_version}"]
  }
}

// We launch Vault into an ASG so that it can properly bring them up for us.
resource "aws_autoscaling_group" "nomad-servers" {
  name                      = "nomad servers - ${aws_launch_configuration.nomad-server.name}"
  launch_configuration      = "${aws_launch_configuration.nomad-server.name}"
  availability_zones        = ["${var.availability_zone}"]
  min_size                  = "${var.servers}"
  max_size                  = "${var.servers}"
  desired_capacity          = "${var.servers}"
  health_check_grace_period = 15
  health_check_type         = "EC2"
  vpc_zone_identifier       = ["${var.subnet}"]

  # load_balancers            = ["${aws_elb.nomad_server.id}"]

  tag {
    key                 = "Name"
    value               = "${lookup(var.resource_tags, "ClusterName")}"
    propagate_at_launch = true
  }
  tag {
    key                 = "Owner"
    value               = "${lookup(var.resource_tags, "Owner")}"
    propagate_at_launch = true
  }
  tag {
    key                 = "TTL"
    value               = "${lookup(var.resource_tags, "TTL")}"
    propagate_at_launch = true
  }
  tag {
    key                 = "Role"
    value               = "nomad_server"
    propagate_at_launch = true
  }
  tag {
    key                 = "Env"
    value               = "${var.env}"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "nomad-server" {
  image_id        = "${data.aws_ami.nomad_server_ami.id}"
  instance_type   = "${var.instance_type}"
  key_name        = "${var.key_name}"
  security_groups = ["${aws_security_group.nomad.id}"]
  user_data       = "${template_file.install-server.rendered}"
}
