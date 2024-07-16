provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./networking"
}
output "vpcid_output" {
  value = module.vpc.vpc_id
}