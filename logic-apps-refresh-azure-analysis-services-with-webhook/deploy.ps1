# PARAMETERS
$ErrorActionPreference = "Stop"

# New Logic App details
$logicAppSubscriptionName = "Microsoft Azure Sponsorship"
$logicAppResourceGroupName = "test"

# Existing Analysis Services details
$analysisServicesSubscriptionName = "Microsoft Azure Sponsorship"
$analysisServicesResourceGroupName = "az-analysis-services"
$analysisServicesName = "analysisservicesdemo"

Write-Host "[$(Get-Date)] Starting..." -ForegroundColor Green

# Set active subscription for the deployment
Write-Host "[$(Get-Date)] Selecting subscription to deploy logic app"
Select-AzSubscription $logicAppSubscriptionName

# Deploy the logic app
Write-Host "[$(Get-Date)] Deploying the logic app" -ForegroundColor Cyan
$deployment = New-AzResourceGroupDeployment `
    -ResourceGroupName $logicAppResourceGroupName `
    -Name "la-depl-$((Get-Date).Ticks)" `
    -TemplateFile .\template.json `
    -TemplateParameterFile .\template.parameters.json

# Get Logic App info from the deployment
$logicAppIdentityPrincipalId = $deployment.outputs.identityPrinicpalId.value;
$logicAppIdentityTenantId = $deployment.outputs.identityTenantlId.value;
$logicAppName = $deployment.outputs.logicAppName.value;

# Alternative way to get Principal & Tenant ID for Managed Identity
$logicAppResource = Get-AzResource `
    -Name $logicAppName `
    -ResourceGroupName $logicAppResourceGroupName `
    -ResourceType Microsoft.Logic/workflows
$logicAppIdentityPrincipalId = $logicAppResource.identity.PrincipalId;
$logicAppIdentityTenantId = $logicAppResource.identity.TenantId;

# Get Application Id for the service principal (admins are added by application ids, not principal ids)
$logicAppIdentityAppId = (Get-AzADServicePrincipal -ObjectId $logicAppIdentityPrincipalId).ApplicationId
$logicAppIdentityIdentifier = "app:$logicAppIdentityAppId@$logicAppIdentityTenantId"

Write-Host "[$(Get-Date)] Logic app details" -ForegroundColor Cyan
Write-Output @{
    "Logic App Name" = $logicAppName;
    "logic App Identity Principal Id" = $logicAppIdentityPrincipalId;
    "logic App Identity App Id" = $logicAppIdentityAppId;
    "logic App Identity Tenant Id" = $logicAppIdentityTenantId;
    "logic App Identity Identifier" = $logicAppIdentityIdentifier;
}

# Set active subscription for the analysis services update
Write-Host "[$(Get-Date)] Selecting subscription to update analysis services"
Select-AzSubscription $analysisServicesSubscriptionName

# Get Analysis Services administrators list
Write-Host "[$(Get-Date)] Getting existing resource of azure analysis services"
$analysisServices = Get-AzAnalysisServicesServer `
    -Name $analysisServicesName `
    -ResourceGroupName $analysisServicesResourceGroupName
$analysisServicesAdministrators = $analysisServices.AsAdministrators

# Add Logic App as admin if entry doesn't exist already
Write-Host "[$(Get-Date)] Adding Logic App Managed Identity as the Administrator" -ForegroundColor Green

If (-not ($analysisServicesAdministrators -contains $logicAppIdentityIdentifier)) {

    $analysisServicesAdministrators.Add($logicAppIdentityIdentifier);

    Set-AzAnalysisServicesServer `
        -Name $analysisServicesName `
        -ResourceGroupName $analysisServicesResourceGroupName `
        -Administrator ($analysisServicesAdministrators -join ",")

    Write-Host "[$(Get-Date)] Admin added" -ForegroundColor Green

} else {

    Write-Host "[$(Get-Date)] Admin already exists. Skipping..." -ForegroundColor Cyan

}

