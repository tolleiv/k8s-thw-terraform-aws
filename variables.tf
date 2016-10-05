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