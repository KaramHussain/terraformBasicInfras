terraform {
  backend "s3" {
    key = "terraform/tfstate.tfstate"
    bucket = "karamterraformstatefile"
    region = "us-east-1"
  }
}