variable "environment" {
  description = "Environment"
  type        = string
}

variable "application_name" {
  description = "Application name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
}

variable "eks_version" {
  type        = string
  description = "EKS version"

}

variable "cluster_endpoint_public_access" {
  description = "Public access for eks cluster"
  type        = bool
  default     = false
}

variable "google_client_id" {
  description = "Google client ID for lambda authorizer"
  type        = string
}