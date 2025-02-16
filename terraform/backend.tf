# terraform {
#   backend "local" {
#     path = "./terraform-states/vpc/terraform.tfstate"
#   }
# }

terraform {
  backend "s3" {
    bucket         = "weather-tfstate"
    key            = "dev/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
  }
}