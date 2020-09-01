provider "aws" {
  region     = "eu-central-1"
}

resource "aws_default_vpc" "default" {}
