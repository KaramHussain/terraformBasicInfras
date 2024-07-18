provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./modules/networking"
}


module "compute" {
  source = "./modules/compute"
  vpc_id = module.vpc.vpc_id
  NI_ID  = module.vpc.nginx_NI_ID
}



