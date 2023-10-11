variable "vpc_cidr_block" {
    default = "10.0.0.0/16"
}

variable "subnet_cidr_block" {
    default = "10.0.1.0/24"
}

variable "avail_zone" {
    default = "eu-central-1a"
}

variable "env_prefix" {
    default = "dev"
}

variable "instance_type" {
    default = "t2.micro"
}

variable "region" {
    default = "eu-central-1"
}