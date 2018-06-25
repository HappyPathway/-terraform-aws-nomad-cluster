module "consul_instance_profile" {
  region        = "${var.region}"
  source        = "./instance-policy"
  resource_tags = "${var.resource_tags}"
}
