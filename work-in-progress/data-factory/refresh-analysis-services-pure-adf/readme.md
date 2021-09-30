### Summary

## Brief
This code will refresh Azure Analysis Services model and wait for it's completion using purely Azure Data Factory activities.

Alternative approach [using Azure Logic Apps is described here](../refresh-analysis-services-logic-app/index.md).

## Services used

- Azure Data Factory
- Azure Analysis Services

## Prerequisites



## Diagram

## Deployment steps

* Assign Azure Analysis Services Admin to **Azure Data Factory**

  * Option 1 - via SSMS (SQL Server Management Studio)
    * Login to AAS via SSMS
    * Right-click on the server
    * Select Properties
    * 

  * Option 2 - via Azure PowerShell (Cloud Shell or ran locally)
  ```PowerShell
  $dataFactoryName = "az-analysis-services-adf"
  
  ```