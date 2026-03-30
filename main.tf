terraform {
  required_providers {
    btp = {
      source  = "SAP/btp"
      version = "~> 1.19.0"
    }
    cloudfoundry = {
      source  = "cloudfoundry/cloudfoundry"
      version = "1.12.0"
    }
  }
}

provider "btp" {
  globalaccount = var.globalaccount
  username      = var.btp_username
  password      = var.btp_password
}


provider "cloudfoundry" {
  api_url  = local.cf_api_url
  user     = var.btp_username
  password = var.btp_password
}