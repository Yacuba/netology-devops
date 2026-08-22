module "s3_bucket" {
  source      = "git::https://github.com/terraform-yc-modules/terraform-yc-s3.git?ref=e4017d77de83fe105604fa7b012bc809a77c2fa2"
  bucket_name = var.bucket_name
  max_size    = 1073741824
}
