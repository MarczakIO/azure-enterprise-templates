## Refreshing Azure Analysis Services models from Azure Data Factory pipelines

# Summary
This small manual should help data engineers refresh Azure Analysis Services from Azure Data Factory in just few minutes. 
## Brief
This code will refresh Azure Analysis Services model and wait for it's completion using Azure Data Factory Webhook activity to call Azure Logic App.

## Services used

- Azure Data Factory
- Azure Analysis Services

## Prerequisites

- Permissions in Azure to 
  - Deploy ARM templates, and 
  - Admin rights Azure Analysis Services
- At least one model deployed in AAS

## Diagram
 ![Diagram](images/diagram.svg)

## Benefits
- Azure Logic Apps are extremely cheap small asynchronous tasks. There is literally 0$ costs involved in just waiting as consumption based (serverless) Logic Apps have no infrasurcture associated with them. 
- No Data Factory cost associated for waiting when using Webhook!
  ![OK](images/webhook-cost.png) 

## Flow Diagram
 ![Diagram](images/diagram-flow.svg) 

# Deployment Steps

1. Create Logic App from ARM template
2. Assign Logic App Managed Identity to Azure Analysis Services as an administrator
3. Get Logic App URL 
4. Add & configure Webhook Activity in Data Factory

# Deployment Steps (PowerShell or CloudShell)

1. Create Logic App from ARM template

    ```PowerShell
    New-AzResourceGroupDeployment `
        -ResourceGroupName <your_logic_app_resource_group_name> `
        -LogicAppName <your_logic_app_name> `
        -TemplateUri "https://raw.githubusercontent.com/MarczakIO/azure-enterprise-templates/main/data-factory/refresh-analysis-services-logic-app/template.json"
    ```

2. Assign Logic App Managed Identity to Azure Analysis Services as an administrator

    ```PowerShell
    Invoke-WebRequest `
      -Uri "https://raw.githubusercontent.com/MarczakIO/azure-enterprise-templates/main/data-factory/refresh-analysis-services-logic-app/assign-resource-identity-as-aas-admin.ps1" `
      -OutFile assign-resource-identity-as-aas-admin.ps1

    .\assign-resource-identity-as-aas-admin.ps1 `
      -resourceName <your_logic_app_name> `
      -resourceType "Microsoft.Logic/workflows" `
      -resourceResourceGroupName <your_logic_app_resource_group_name> `
      -resourceSubscriptionName <your_logic_app_subscription_name> `
      -analysisServicesName <your_analysis_services_name> `
      -analysisServicesResourceGroupName <your_analysis_services_resource_group_name> `
      -analysisServicesSubscriptionName <your_analysis_services_subscription_name>
    ```

3. Get Logic App URL 

    ```PowerShell
    Get-AzLogicAppTriggerCallbackUrl `
      -Name <your_logic_app_name> `
      -ResourceGroupName <your_logic_app_resource_group_name> `
      -TriggerName manual
    ```

4. Add & configure Webhook Activity in Data Factory (described below)

# Deployment Steps (Manual)

1. Create Logic App from ARM template

    * Option 1 - Deploy with ARM template using Azure Portal
    
      [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FMarczakIO%2Fazure-enterprise-templates%2Fmain%2Fdata-factory%2Frefresh-analysis-services-logic-app%2Ftemplate.json)

    * Option 2 - Using [ARM template](../refresh-analysis-services-logic-app/template.json) manually

2. Assign Logic App Managed Identity to Azure Analysis Services as an administrator

     * Option #1 - Use PowerShell manually script located here [assign-resource-identity-as-aas-admin.ps1](assign-resource-identity-as-aas-admin.ps1)

       * Replace six variables with the ones from your environment
         * resourceName
         * resourceResourceGroupName
         * resourceType 
         * resourceSubscriptionName
         * analysisServicesName
         * analysisServicesResourceGroupName
         * analysisServicesSubscriptionName

     * Option #2 - Use SQL Server Management Studio (TO-DO)

# Usage (Data Factory)
Add & configure Webhook Activity in Data Factory

* Open **Azure Data Factory** and add new **Webhook Activity**
  
  ![Activity Configuration](images/webhook-pl-1.png)

  Configure the setup as follows

* **URL** - Get URL from Logic App first step.
    
    * Option #1 - via old UI
      
      ![Activity Configuration](images/logic-app-url.png)
  
    * Option #2 - via new UI
      
      ![Activity Configuration](images/logic-app-url-new.png)
  
    * Option #3 - via PowerShell

      ```PowerShell
      Get-AzLogicAppTriggerCallbackUrl `
        -Name <your_logic_app_name> `
        -ResourceGroupName <your_logic_app_resource_group_name> `
        -TriggerName manual
      ```

* **Method** POST
* **Body** - use this template  
  ```json
  {
      "AAS Model Name": "<model_name>",
      "AAS Refresh Body": {
          "CommitMode": "transactional",
          "MaxParallelism": 2,
          "Objects": [],
          "RetryCount": 2,
          "Type": "Full"
      },
      "AAS Rollout Region": "<rollout_region>",
      "AAS Server Name": "<server_name>",
      "Wait For Sync": <true/false>
  }
  ```
  *Example*
  ```json
  {
      "AAS Model Name": "DemoTabular",
      "AAS Refresh Body": {
          "CommitMode": "transactional",
          "MaxParallelism": 2,
          "Objects": [],
          "RetryCount": 2,
          "Type": "Full"
      },
      "AAS Rollout Region": "westeurope",
      "AAS Server Name": "analysisservicesdemo",
      "Wait For Sync": true
  }
  ```
* **Report status on callback** - Checked
  ***Important!*** - This is important to be checked.
* **Timeout** - Set up maximum time that you expect to refresh to finish in.

  * *Example* configuration

    ![Activity Configuration](images/webhook-setup.png)

2. Debug and test it!

  ![OK](images/webhook-success.png) 