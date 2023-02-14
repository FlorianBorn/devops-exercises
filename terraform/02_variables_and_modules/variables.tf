variable "cidr_vpc" {
  description = "The CIDR block for the main vpc"
  type        = string
}

variable "cidr_public_subnet" {
  description = "The CIDR block for the public subnet"
  type        = string
}

variable "cidr_private_subnet" {
  description = "The CIDR block for the private subnet"
  type        = string
}