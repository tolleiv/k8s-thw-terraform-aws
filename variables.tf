variable "access_key" {
  description = "AWS access key"
}

variable "secret_key" {
  description = "AWS secret access key"
}

variable "region"     {
  description = "AWS region to host your network"
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  description = "CIDR for VPC"
  default     = "10.240.0.0/16"
}
variable "vpc_subnet_cidr" {
  description = "CIDR for VPC"
  default     = "10.240.0.0/24"
}

variable "instance_controller_ips" {
  description = "IPs to pick for the controllers"
  default = {
    "0" = "10.240.0.10"
    "1" = "10.240.0.11"
    "2" = "10.240.0.12"
  }
}
variable "instance_worker_ips" {
  description = "IPs to pick for the controllers"
  default = {
    "0" = "10.240.0.20"
    "1" = "10.240.0.21"
    "2" = "10.240.0.22"
    "3" = "10.240.0.23"
    "4" = "10.240.0.24"
    "5" = "10.240.0.25"
    "6" = "10.240.0.26"
    "7" = "10.240.0.27"
    "8" = "10.240.0.28"
    "9" = "10.240.0.29"
  }
}