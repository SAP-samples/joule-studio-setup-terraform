# Variables for SAP BTP Subaccount
variable "subaccount_name" {
  description = "The display name of the subaccount."
  type        = string
  default     = "DEFAULT"
}

variable "subaccount_region" {
  description = "The region for the subaccount (e.g., eu10, us10)."
  type        = string
  default     = "eu10"
}

variable "subaccount_subdomain" {
  description = "The subdomain for the subaccount."
  type        = string
  default    = "jstudio-subdomain"
}

variable "subaccount_stage" {
  description = "The stage for the subaccount (e.g., dev, test, prod)."
  type        = string
  default     = "prod"
}

variable "globalaccount" {
  description = "The globalaccount name"
  type        = string
}

variable "btp_username" {
  description = "SAP BTP username (email)"
  type        = string
  sensitive   = true
}

variable "btp_password" {
  description = "SAP BTP password"
  type        = string
  sensitive   = true
}

variable "cf_api_url" {
  description = "The Cloud Foundry API URL"
  type        = string
  default     = "https://api.cf.eu10.hana.ondemand.com"
}

variable "custom_idp_origin" {
  type        = string
  description = "Defines the custom IDP origin for role collection assignments (e.g., sap.custom, sap.ids)"
  default     = "sap.custom"
}

variable "identity_provider" {
  type        = string
  description = "The SAP Cloud Identity Services (IAS) tenant URL for trust configuration (e.g., your-tenant.accounts.ondemand.com)"
}

variable "subaccount_emergency_admins" {
  type        = list(string)
  description = "List of emergency admins for the SAP BTP subaccount"
  default     = []
}

variable "subaccount_viewers" {
  type        = list(string)
  description = "List of users to be assigned the Subaccount Viewer role in the SAP BTP subaccount"
  default     = []
}

variable "cf_session_token" {
  type        = string
  description = "The session token for Cloud Foundry authentication"
  sensitive   = true # This hides the code from your terminal logs
  default = null
}