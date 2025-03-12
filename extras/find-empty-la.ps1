# Ensure you are logged into Azure
# Connect-AzAccount
 
# Install Az.ResourceGraph module if not installed
if (-not (Get-Module -ListAvailable -Name Az.ResourceGraph)) {
    Install-Module -Name Az.ResourceGraph -Scope CurrentUser -Force
}
 
# Query Azure Resource Graph to get all App Service resource IDs
$query = @"
resourcecontainers
| where ['type'] == 'microsoft.resources/subscriptions'
| where properties.managementGroupAncestorsChain[0].displayName startswith "A"
         or properties.managementGroupAncestorsChain[0].displayName startswith "B"
         or properties.managementGroupAncestorsChain[0].displayName startswith "C"
         or properties.managementGroupAncestorsChain[0].displayName startswith "D"
| project subscriptionId
| join kind=inner (
    resources
    | where type =~ 'microsoft.web/sites'
    | where kind == 'functionapp,workflowapp'
) on subscriptionId
| project id
"@
 
# Run the query across all subscriptions
$appServices = Search-AzGraph -Query $query -First 1000
 
# Output the list of resource IDs
$appServices.id
 
$laEmptyCount = 0
foreach( $id in $appServices.id ) {
    $workflows = Invoke-AzRestMethod -Uri "https://management.azure.com/$id/workflows?api-version=2024-04-01"
    $parsedResponse = $workflows.Content | ConvertFrom-Json
    if($parsedResponse.value.Count -eq 0) {
        $laEmptyCount = $laEmptyCount + 1
        $laEmptyCount
        Write-Host "Unused LA: $$id"
    }
}
