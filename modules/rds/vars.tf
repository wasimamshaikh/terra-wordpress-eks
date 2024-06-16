//Create these variables that is used in this module and are assigned during run time from different modules.

variable "subnets" {
  type  = list(string)
}

variable "db_password" {}

variable "vpc_id" {}

variable "sg_id" {}