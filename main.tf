provider "aws" {
    region = "ap-south-1"
    access_key = var.access_key
    secret_key = var.secret_key
}

provider "aws" {
    region = "us-east-1"
    alias = "disaster"
    access_key = var.access_key
    secret_key = var.secret_key
}