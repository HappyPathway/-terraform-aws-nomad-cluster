variable "availability_zone" {
  default     = "us-east-1a"
  description = "Availability zones for launching the Vault instances"
}

variable "instance_type" {
  default     = "m3.medium"
  description = "Instance type for Vault instances"
}

variable "key_name" {
  default     = "default"
  description = "SSH key name for Vault instances"
}

variable "servers" {
  default     = "3"
  description = "number of Nomad servers"
}

variable "clients" {
  default     = "3"
  description = "number of Nomad clients"
}

variable "subnet" {
  description = "list of subnets to launch Vault within"
}

variable "vpc_id" {
  description = "VPC ID"
}

variable "resource_tags" {
  type        = "map"
  default     = {}
  description = "Resource Tags. Get applied anywhere tags can be applied"
}

variable "consul_cluster" {
  type        = "string"
  description = "IP Address of consul cluster bootstrap host"
}

variable "region" {
  type        = "string"
  description = "AWS Region"
}

variable "service_name" {
  default = "nomad"
}

variable "service_version" {
  default = "1.0.0"
}

variable "vault_token" {
  description = "Vault Token"
  type        = "string"
}

variable "vault_cluster" {
  description = "Vault Cluster Address"
  type        = "string"
}
