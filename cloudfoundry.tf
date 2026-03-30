locals {
  # creates valid CF instance name by lowercasing, replacing invalid characters with hyphens, collapsing consecutive hyphens, and trimming leading/trailing hyphens.
  cf_instance_name = trim(
    replace(
      replace(lower("${var.subaccount_name}-cf-instance"), "/[^a-z0-9-]/", "-"),
      "/--+/", "-"
    ),
    "-"
  )
  cf_org_id          = jsondecode(btp_subaccount_environment_instance.cloudfoundry.labels)["Org ID"]
  cf_org_name        = jsondecode(btp_subaccount_environment_instance.cloudfoundry.labels)["Org Name"]
  cf_landscape_label = "cf-${var.subaccount_region}"
  cf_api_url         = "https://api.cf.${var.subaccount_region}.hana.ondemand.com"
}

resource "btp_subaccount_environment_instance" "cloudfoundry" {
  subaccount_id    = btp_subaccount.main.id
  name             = "cloudfoundry"
  landscape_label  = local.cf_landscape_label
  environment_type = "cloudfoundry"
  service_name     = "cloudfoundry"
  plan_name        = "standard"
  parameters = jsonencode({
    instance_name = local.cf_instance_name
    memory        = 1024
  })
  timeouts = {
    create = "1h"
    update = "35m"
    delete = "30m"
  }

  lifecycle {
    ignore_changes = [landscape_label]
  }
}

# create a cloudfoundry Space in the created subaccount
resource "cloudfoundry_space" "space" {
  name       = "dev"
  org        = local.cf_org_id
  depends_on = [btp_subaccount_environment_instance.cloudfoundry]
}

# ------------------------------------------------------------------------------------------------------
# Create the CF users
# ------------------------------------------------------------------------------------------------------

resource "cloudfoundry_space_role" "manager" {
  space      = cloudfoundry_space.space.id
  type       = "space_manager"
  username   = var.btp_username
  origin     = "sap.ids"
  depends_on = [cloudfoundry_space.space]
}