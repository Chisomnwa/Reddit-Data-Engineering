terraform {
  backend "s3" {
    bucket = "reddit-etl-backend-bucket"
    key    = "reddit/dev/terraform.tfstate" # You define this path yourself. It's like a folder structure.
    region = "af-south-1"
  }
}
