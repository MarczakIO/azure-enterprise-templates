param (
    $dataFactoryName = "",
    $dataFactoryResourceGroupName = "",
    $dataFactorySubscriptionName = "",
    
    $analysisServicesName = "",
    $analysisServicesResourceGroupName = "",
    $analysisServicesSubscriptionName = ""
)

$ErrorActionPreference = "Stop"
Write-Host "Running..."

Select-AzSubscription -Subscription $dataFactorySubscriptionName

$resourceType = "Microsoft.DataFactory/factories"

$resource = Get-AzResource `
    -Name $dataFactoryName `
    -ResourceGroupName $dataFactoryResourceGroupName `
    -ResourceType $resourceType
$managedIdentityPrincipalId = $resource.identity.PrincipalId;
$managedIdentityTenantId = $resource.identity.TenantId;

# Get Application Id for the service principal (admins are added by application ids, not principal ids)
$managedIdentityAppId = (Get-AzADServicePrincipal `
    -ObjectId $managedIdentityPrincipalId).ApplicationId
$managedIdentityAppIdentifier = "app:$managedIdentityAppId@$managedIdentityTenantId"

Write-Host "[$(Get-Date)] Resource Details" -ForegroundColor Cyan
Write-Output "Resource Name: $($resource.Name)"
Write-Output "Managed Identity Principal Id: $($managedIdentityPrincipalId)"
Write-Output "Managed Identity App Id: $($managedIdentityAppId)"
Write-Output "Managed Identity Tenant Id: $($managedIdentityTenantId)"
Write-Output "Managed Identity Identifier: $($managedIdentityAppIdentifier)" -ForegroundColor Cyan


# Set active subscription for the analysis services update
Write-Host "[$(Get-Date)] Selecting subscription to update analysis services"
Select-AzSubscription $analysisServicesSubscriptionName

# Get Analysis Services administrators list
Write-Host "[$(Get-Date)] Getting existing resource of azure analysis services"
$analysisServices = Get-AzAnalysisServicesServer `
    -Name $analysisServicesName `
    -ResourceGroupName $analysisServicesResourceGroupName


if ($analysisServices.State -ne 'Succeeded') {
    Write-Host "AAS is not running... stopping!"
} else {
    $analysisServicesAdministrators = $analysisServices.AsAdministrators

    # Add Logic App as admin if entry doesn't exist already
    Write-Host "[$(Get-Date)] Adding Managed Identity as the Administrator" -ForegroundColor Green

    If (-not ($analysisServicesAdministrators -contains $managedIdentityAppIdentifier)) {

        $analysisServicesAdministrators.Add($managedIdentityAppIdentifier);

        Set-AzAnalysisServicesServer `
            -Name $analysisServicesName `
            -ResourceGroupName $analysisServicesResourceGroupName `
            -Administrator ($analysisServicesAdministrators -join ",")

        Write-Host "[$(Get-Date)] Admin added" -ForegroundColor Green

    } else {

        Write-Host "[$(Get-Date)] Admin already exists. Skipping..." -ForegroundColor Cyan

    }
}


