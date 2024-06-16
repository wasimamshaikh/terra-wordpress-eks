variable "REGION" {
  default = "us-east-1"
}

variable "VPC_CIDR" {
  default = "172.20.0.0/16"
}

variable "PUBSUB1CIDR" {
  default = "172.20.1.0/24"
}

variable "PUBSUB2CIDR" {
  default = "172.20.2.0/24"
}

variable "ZONE1" {
  default = "us-east-1a"
}

variable "ZONE2" {
  default = "us-east-1b"
}

variable "ENTER_DB_PASS"{}