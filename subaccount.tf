locals {
  raw_subdomain = lower("${var.subaccount_name}-${var.subaccount_subdomain}-${var.subaccount_region}")
  # Sanitizes the raw subdomain by replacing invalid characters with hyphens, collapsing 
  # consecutive hyphens into one, and trimming hyphens from both ends.
  subaccount_subdomain = trim(
    replace(replace(local.raw_subdomain, "/[^a-z0-9-]/", "-"), "/--+/", "-"),
    "-"
  )
}

resource "btp_subaccount" "main" {
  name      = var.subaccount_name
  region    = var.subaccount_region
  subdomain = local.subaccount_subdomain
}
