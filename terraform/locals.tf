locals {
  short_aws_region = "ase1"
  name_prefix      = "mw-${var.environment}-${local.short_aws_region}-${var.application_name}"
  tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )
}