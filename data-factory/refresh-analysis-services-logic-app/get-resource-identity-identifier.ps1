param (
    $resourceName = "",
    $resourceType = "",
    $resourceResourceGroupName = "",
    $resourceSubscriptionName = "",
)

$ErrorActionPreference = "Stop"
Write-Host "Running..."

Select-AzSubscription -Subscription $resourceSubscriptionName

$resource = Get-AzResource `
    -Name $resourceName `
    -ResourceGroupName $resourceResourceGroupName `
    -ResourceType $resourceType
$managedIdentityPrincipalId = $resource.identity.PrincipalId;
$managedIdentityTenantId = $resource.identity.TenantId;

# Get Application Id for the service principal (admins are added by application ids, not principal ids)
$managedIdentityAppId = (Get-AzADServicePrincipal `
    -ObjectId $managedIdentityPrincipalId).ApplicationId
$managedIdentityAppIdentifier = "app:$managedIdentityAppId@$managedIdentityTenantId"

Write-Host "[$(Get-Date)] Resource Details" -ForegroundColor Cyan
Write-Output "Managed Identity Identifier: $($managedIdentityAppIdentifier)" -ForegroundColor Cyan