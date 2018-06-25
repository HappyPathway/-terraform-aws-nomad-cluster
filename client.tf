resource "template_file" "install-client" {
  template = "${file("${path.module}/scripts/install.sh.tpl")}"

  vars {
    consul_cluster    = "${var.consul_cluster}"
    vault_cluster     = "${var.vault_cluster}"
    vault_token       = "${var.vault_token}"
    nomad_client      = "true"
    nomad_server      = "false"
    nomad_datacenter  = "${lookup(var.resource_tags, "ClusterName")}"
    consul_datacenter = "${var.consul_datacenter}"
    servers           = "${var.servers}"
    env               = "${var.env}"
  }
}

data "aws_ami" "nomad_client_ami" {
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
resource "aws_autoscaling_group" "nomad-clients" {
  name                      = "nomad clients - ${aws_launch_configuration.nomad-client.name}"
  launch_configuration      = "${aws_launch_configuration.nomad-client.name}"
  availability_zones        = ["${var.availability_zone}"]
  min_size                  = "${var.clients}"
  max_size                  = "${var.clients}"
  desired_capacity          = "${var.clients}"
  health_check_grace_period = 15
  health_check_type         = "EC2"
  vpc_zone_identifier       = ["${var.subnet}"]

  # load_balancers            = ["${aws_elb.nomad_client.id}"]

  tag {
    key                 = "Name"
    value               = "${lookup(var.resource_tags, "ClusterName")}-${var.env}"
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
    value               = "nomad_client"
    propagate_at_launch = true
  }
  tag {
    key                 = "Env"
    value               = "${var.env}"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "nomad-client" {
  image_id        = "${data.aws_ami.nomad_client_ami.id}"
  instance_type   = "${var.instance_type}"
  key_name        = "${var.key_name}"
  security_groups = ["${aws_security_group.nomad.id}"]
  user_data       = "${template_file.install-client.rendered}"
}
