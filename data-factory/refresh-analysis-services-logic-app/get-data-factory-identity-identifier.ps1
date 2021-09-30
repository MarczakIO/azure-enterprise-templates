$dataFactoryName = ""
$dataFactoryResourceGroupName = ""
$dataFactorySubscriptionName = ""

Select-AzSubscription -Subscription $dataFactorySubscriptionName

$resource = Get-AzResource `
    -Name $dataFactoryName `
    -ResourceGroupName $dataFactoryResourceGroupName `
    -ResourceType "Microsoft.DataFactory/factories"
$managedIdentityPrincipalId = $resource.identity.PrincipalId;
$managedIdentityTenantId = $resource.identity.TenantId;

# Get Application Id for the service principal (admins are added by application ids, not principal ids)
$managedIdentityAppId = (Get-AzADServicePrincipal `
    -ObjectId $managedIdentityPrincipalId).ApplicationId
$managedIdentityAppIdentifier = "app:$managedIdentityAppId@$managedIdentityTenantId"

Write-Host "Managed Identity Identifier: $($managedIdentityAppIdentifier)" -ForegroundColor Cyan
