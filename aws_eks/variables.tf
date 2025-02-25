variable "name" {
  default = "test"
}

variable "subnets" {
  description = "list of subnet object to create in vpc"
  type = map(object({
    cidr = string,
    az   = string
  }))

}

variable "cluster-name" {
  type = string
}

variable "cluster-version" {
  type    = string
  default = "1.31"
}