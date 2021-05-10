# This runbook will dismiss a user risk classification. 
#
# This runbook will use the "AzureRunAsConnection" via stored credentials. Please make sure, enough API-permissions are given to this service principal.
# 
# Permissions needed:
# - IdentityRiskyUser.ReadWrite.All

#Requires -Modules MEMPSToolkit, RealmJoin.RunbookHelper

param(
    [Parameter(Mandatory = $true)]
    [String]$UserName,
    [String]$OrganizationID
)

#region module check
$neededModule = "MEMPSToolkit"

if (-not (Get-Module -ListAvailable $neededModule)) {
    throw ($neededModule + " is not available and can not be installed automatically. Please check.")
}
else {
    Import-Module $neededModule
    Write-Output ("Module " + $neededModule + " is available.")
}
#endregion

#region Authentication
# Automation credentials
$automationCredsName = "realmjoin-automation-cred"

Write-Output "Connect to Graph API..."
$token = Get-AzAutomationCredLoginToken -tenant $OrganizationID -automationCredName $automationCredsName
#endregion

write-output ("Checking risk status of " + $UserName) 
$riskyUsers = get-RiskyUsers -authToken $token
$targetUser = ($riskyUsers | where-Object { $_.userPrincipalName -ieq $UserName })
if (-not $targetUser) {
    Write-Output ($UserName + " is not in list of risky users. No action taken.")
    exit
}

Write-Output ("Current risk: " + $targetUser.riskState)
if (($targetUser.riskState -eq "atRisk") -or ($targetUser.riskState -eq "confirmedCompromised")) {
    Write-Output ("Dismissing.")
    set-DismissRiskyUser -authToken $token -userId $targetUser.id 
    Write-Output ("User risk for " + $UserName + " successfully dismissed.")
} else {
    Write-Output ("User " + $UserName + " not at risk. No action taken.")
}
