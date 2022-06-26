variable "vpn_server_instance_name" {
  description = "Name of the VPN Server instance"
  type        = string
  default     = "vpn-server"
}

variable "client_instance_name" {
  description = "Name of the VPN Client instance"
  type        = string
  default     = "client"
}

variable "webserver_instance_name" {
  description = "Name of the Web Server instance"
  type        = string
  default     = "webserver"
}
