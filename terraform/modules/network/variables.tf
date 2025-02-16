variable "cidr_block" {
  description = "The IPv4 CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "frontend_cidr_block" {
  description = "The IPv4 CIDR block for the frontend subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "application_cidr_block" {
  description = "The IPv4 CIDR block for the frontend subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "database_cidr_block" {
  description = "The IPv4 CIDR block for the database subnets"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}