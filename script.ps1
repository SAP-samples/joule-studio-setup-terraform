$CF_API = "https://api.cf.eu10.hana.ondemand.com"

Write-Host "Step 1: Logging into Cloud Foundry (SSO)..."
# This will open your browser once.
cf login -a $CF_API --sso

Write-Host "Step 2: Launching Terraform..."
# We export the BTP SSO variable so the BTP provider uses your active browser session and
# this opens your browser once again
$env:BTP_ENABLE_SSO = "true"

# Run terraform and inject the token automatically
$token = (cf oauth-token) -replace "^bearer ", ""
terraform plan -var="cf_session_token=$token"
