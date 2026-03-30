# ------------------------------------------------------------------------------------------------------
# Assign subaccount administrator role to certain users (emergency admins)
# ------------------------------------------------------------------------------------------------------

resource "btp_subaccount_role_collection_assignment" "emergency_administrators" {
  for_each             = toset(var.subaccount_emergency_admins)
  subaccount_id        = btp_subaccount.main.id
  role_collection_name = "Subaccount Administrator"
  user_name            = each.value
}

# ------------------------------------------------------------------------------------------------------
# Prepare and setup app: Cloud Management Service
# ------------------------------------------------------------------------------------------------------

# Entitlement for Cloud Management Service
resource "btp_subaccount_entitlement" "cis" {
  subaccount_id = btp_subaccount.main.id
  service_name  = "cis"
  plan_name     = "local"
}

# Service Instance for Cloud Management Service
resource "btp_subaccount_service_instance" "cis" {
  subaccount_id  = btp_subaccount.main.id
  name           = "cis-local"
  serviceplan_id = data.btp_subaccount_service_plan.cis.id
  depends_on     = [btp_subaccount_entitlement.cis]
}

# Data source to get the service plan ID
data "btp_subaccount_service_plan" "cis" {
  subaccount_id = btp_subaccount.main.id
  name          = "local"
  offering_name = "cis"
  depends_on    = [btp_subaccount_entitlement.cis]
}

# ------------------------------------------------------------------------------------------------------
# Get subaccount data
# ------------------------------------------------------------------------------------------------------

# Get plan for destination service
data "btp_subaccount_service_plan" "by_name" {
  subaccount_id = btp_subaccount.main.id
  name          = "lite"
  offering_name = "destination"
}

data "btp_subaccount" "subaccount" {
  id = btp_subaccount.main.id
}


# ------------------------------------------------------------------------------------------------------
# Prepare and setup app: SAP Build Process Automation subscription
# ------------------------------------------------------------------------------------------------------
# 2. Trust configuration (required for SPA and Joule)
resource "btp_subaccount_trust_configuration" "oidc_trust" {
  subaccount_id     = btp_subaccount.main.id
  identity_provider = var.identity_provider
}
# Entitle subaccount for usage of SAP Build Process Automation
resource "btp_subaccount_entitlement" "build_process_automation_build-default" {
  subaccount_id = btp_subaccount.main.id
  service_name  = "process-automation"
  plan_name     = "build-default"
}

# Create app subscription to  SAP Build Process Automation
resource "btp_subaccount_subscription" "build_process_automation_build-default" {
  subaccount_id = btp_subaccount.main.id
  app_name      = "process-automation"
  plan_name     = "build-default"
  timeouts = {
    create = "45m"
    update = "30m"
    delete = "20m"
  }
  depends_on = [btp_subaccount_entitlement.build_process_automation_build-default,
  btp_subaccount_trust_configuration.oidc_trust]
}

# ------------------------------------------------------------------------------------------------------
# Assign "ProcessAutomationAdmin" and "ProcessAutomationDeveloper" to the btp user
# ------------------------------------------------------------------------------------------------------
resource "btp_subaccount_role_collection_assignment" "ProcessAutomationAdmin" {
  depends_on           = [btp_subaccount_subscription.build_process_automation_build-default]
  subaccount_id        = btp_subaccount.main.id
  role_collection_name = "ProcessAutomationAdmin"
  user_name            = var.btp_username
  origin               = var.custom_idp_origin
}

# Assignments for groups
resource "btp_subaccount_role_collection_assignment" "ProcessAutomationAdmin_groups" {
  for_each             = toset(["Devs"])
  subaccount_id        = btp_subaccount.main.id
  role_collection_name = "ProcessAutomationAdmin"
  group_name           = each.value
  origin               = var.custom_idp_origin
  depends_on           = [btp_subaccount_role_collection_assignment.ProcessAutomationAdmin]
}

resource "btp_subaccount_role_collection_assignment" "ProcessAutomationDeveloper" {
  depends_on           = [btp_subaccount_subscription.build_process_automation_build-default]
  subaccount_id        = btp_subaccount.main.id
  role_collection_name = "ProcessAutomationDeveloper"
  user_name            = var.btp_username
  origin               = var.custom_idp_origin
}

# Assignments for groups
resource "btp_subaccount_role_collection_assignment" "ProcessAutomationDeveloper_groups" {
  for_each             = toset(["Joule Studio CodeJam"])
  subaccount_id        = btp_subaccount.main.id
  role_collection_name = "ProcessAutomationDeveloper"
  group_name           = each.value
  origin               = var.custom_idp_origin
  depends_on           = [btp_subaccount_role_collection_assignment.ProcessAutomationDeveloper]
}

# ------------------------------------------------------------------------------------------------------
# Prepare and setup app: Joule subscription
# ------------------------------------------------------------------------------------------------------

resource "btp_subaccount_entitlement" "das-application" {
  subaccount_id = btp_subaccount.main.id
  service_name  = "das-application"
  plan_name     = "standard"
}

resource "btp_subaccount_subscription" "das-application_ias" {
  subaccount_id = btp_subaccount.main.id
  app_name      = "das-application-ias"
  plan_name     = "standard"

  parameters = jsonencode({
    capabilityPackage           = "build-process-automation"
    subaccountId                = btp_subaccount.main.id
    subaccountName              = btp_subaccount.main.name
    orgId                       = local.cf_org_id
    spaceId                     = cloudfoundry_space.space.id
    conversationInsightsConsent = true
    integrationLandscape        = "testing"
  })

  depends_on = [
    btp_subaccount_entitlement.das-application,
    btp_subaccount_subscription.build_process_automation_build-default,
    cloudfoundry_space.space
  ]

  timeouts = {
    create = "25m"
  }
}

# ------------------------------------------------------------------------------------------------------
# Create Role Collection for Joule
# ------------------------------------------------------------------------------------------------------
data "btp_subaccount_roles" "all" {
  subaccount_id = btp_subaccount.main.id
  depends_on    = [btp_subaccount_subscription.das-application_ias]
}

resource "btp_subaccount_role_collection" "Joule_Studio" {
  subaccount_id = btp_subaccount.main.id
  name          = "Joule_Studio"
  description   = "Assigns end user and extensibility developer"

  roles = [
    for role in data.btp_subaccount_roles.all.values : {
      name                 = role.name
      role_template_app_id = role.app_id
      role_template_name   = role.role_template_name
    } if contains(["end_user", "extensibility_developer"], role.name)
  ]
  depends_on = [btp_subaccount_subscription.das-application_ias]
}

# ------------------------------------------------------------------------------------------------------
# Assign btp username to the role collection Joule_Studio
# ------------------------------------------------------------------------------------------------------
resource "btp_subaccount_role_collection_assignment" "Joule_Studio" {
  depends_on           = [btp_subaccount_role_collection.Joule_Studio]
  subaccount_id        = btp_subaccount.main.id
  role_collection_name = "Joule_Studio"
  user_name            = var.btp_username
  origin               = var.custom_idp_origin
}


# Assignments for groups
resource "btp_subaccount_role_collection_assignment" "Joule_Studio_groups" {
  for_each             = toset(["Devs", "Joule Studio CodeJam"])
  subaccount_id        = btp_subaccount.main.id
  role_collection_name = "Joule_Studio"
  group_name           = each.value
  origin               = var.custom_idp_origin
  depends_on           = [btp_subaccount_role_collection_assignment.Joule_Studio]
}

# ------------------------------------------------------------------------------------------------------
# Assign subaccount viewer role to certain users
# ------------------------------------------------------------------------------------------------------

resource "btp_subaccount_role_collection_assignment" "subaccount_viewers" {
  for_each             = toset(var.subaccount_viewers)
  subaccount_id        = btp_subaccount.main.id
  role_collection_name = "Subaccount Viewer"
  user_name            = each.value
  origin               = "sap.default"
}


# ------------------------------------------------------------------------------------------------------
# Prepare and setup app: SAP Build Workzone, standard edition
# ------------------------------------------------------------------------------------------------------
# Entitle subaccount for usage of app  destination SAP Build Workzone, standard edition
resource "btp_subaccount_entitlement" "build_workzone_standard_free" {
  subaccount_id = btp_subaccount.main.id
  service_name  = "SAPLaunchpad"
  plan_name     = "free"
  amount        = 1
}
# Create app subscription to SAP Build Workzone, standard edition (depends on entitlement)
resource "btp_subaccount_subscription" "build_workzone_standard_free" {
  subaccount_id = btp_subaccount.main.id
  app_name      = "SAPLaunchpad"
  plan_name     = "free"
  depends_on = [btp_subaccount_entitlement.build_workzone_standard_free,
  btp_subaccount_subscription.build_process_automation_build-default, btp_subaccount_trust_configuration.oidc_trust]
  timeouts = {
    create = "10m"
  }
}

# ------------------------------------------------------------------------------------------------------
# Assign users to the role collection workzone standard 
# ------------------------------------------------------------------------------------------------------
resource "btp_subaccount_role_collection_assignment" "launchpad_admin" {
  subaccount_id        = btp_subaccount.main.id
  role_collection_name = "Launchpad_Admin"
  user_name            = var.btp_username
  origin               = var.custom_idp_origin
  depends_on           = [btp_subaccount_subscription.build_workzone_standard_free]
}

# Assignments for launchpad standard admin group
resource "btp_subaccount_role_collection_assignment" "launchpad_admin_groups" {
  for_each             = toset(["Launchpad_Admin"])
  subaccount_id        = btp_subaccount.main.id
  role_collection_name = "Launchpad_Admin"
  group_name           = each.value
  origin               = var.custom_idp_origin
  depends_on           = [btp_subaccount_role_collection_assignment.launchpad_admin]
}

