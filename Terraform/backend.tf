terraform {
  # Backend configuration specifies where to store the Terraform state file
  backend "s3" {
    # Name of the S3 bucket where the Terraform state file will be stored
    bucket = "application-backend-v2"
    # Key is the path within the S3 bucket where the Terraform state file will be stored
    key = "app/terraform.tfstate"
    # AWS region where the S3 bucket is located
    region = "us-east-1"
    # DynamoDB table used for state locking to prevent concurrent modifications
    dynamodb_table = "app-locks"
    ## If AWS CLI & TF AWS lib version are different then enable it
    # Skip region validation to avoid additional AWS region checks
    #skip_region_validation = true
  }
}
