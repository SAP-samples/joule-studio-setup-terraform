
output "subaccount_subdomain_name" {
  value       = local.subaccount_subdomain
  description = "Sanitized subaccount_subdomain name"
}

output "subaccount_id" {
  value       = btp_subaccount.main.id
  description = "BTP Subaccount ID"
}

output "cf_org_id" {
  value       = jsondecode(btp_subaccount_environment_instance.cloudfoundry.labels)["Org ID"]
  description = "The Cloud Foundry organization ID"
}

output "cf_instance_name" {
  value       = local.cf_instance_name
  description = "Sanitized Cloud Foundry instance name"
}

output "build_process_automation_url" {
  value       = btp_subaccount_subscription.build_process_automation_build-default.subscription_url
  description = "SAP Build Process Automation application URL"
}

output "cf_api_url" {
  value       = local.cf_api_url
  description = "The Cloud Foundry API URL"
}