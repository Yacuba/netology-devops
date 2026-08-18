module "s3_bucket" {
  source      = "git::https://github.com/terraform-yc-modules/terraform-yc-s3.git?ref=master"
  bucket_name = var.bucket_name
  max_size    = 1073741824
}
