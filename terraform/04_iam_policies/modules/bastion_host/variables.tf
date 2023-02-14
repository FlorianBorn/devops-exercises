variable "baho_vpc_id" {}
variable "baho_vpc_cidr_block" {}
variable "baho_ssh_key_name" {}
variable "baho_subnet_id" {}
variable "baho_ami" {
  description = "Amazon Machine Image used for creating the bastion host"
  default     = "ami-0aa7d40eeae50c9a9" # amazon linux
  type        = string
}
variable "baho_instance_type" {
  description = "Amazon Instance type used for creating the bastion host"
  default     = "t2.micro"
  type        = string
}