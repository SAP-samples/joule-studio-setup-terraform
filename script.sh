CF_API="https://api.cf.eu10.hana.ondemand.com"

echo "Step 1: Logging into Cloud Foundry (SSO)..."
# This will open your browser once.
cf login -a "$CF_API" --sso

echo "Step 2: Launching Terraform..."
# We export the BTP SSO variable so the BTP provider uses your active browser session and 
# this open you browser once again
export BTP_ENABLE_SSO=true

# Run terraform and inject the token automatically
terraform plan -var="cf_session_token=$(cf oauth-token | cut -d ' ' -f 2)"