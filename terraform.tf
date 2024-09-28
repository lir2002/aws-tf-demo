terraform {
  required_providers {
    aws = {
        version = ">=4.49.0"
        source = "hashicorp/aws"
    }
  }
  required_version = ">=1.1.0"
}