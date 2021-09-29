### Summary

## Brief
This code will refresh Azure Analysis Services model and wait for it's completion using Azure Data Factory Webhook activity to call Azure Logic App.

Alternative approach [using Azure Logic Apps is described here](../refresh-analysis-services-logic-app/index.md).

## Services used

- Azure Data Factory
- Azure Analysis Services

## Prerequisites



## Diagram

## Deployment steps

* Deploy **Azure Logic App**

  * Option 1 - deploy with ARM template using Azure Portal
  
    [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FMarczakIO%2Fazure-enterprise-templates%2Fmain%2Fdata-factory%2Frefresh-analysis-services-logic-app%2Ftemplate.json)

  * Option 2 - Using [ARM template](../refresh-analysis-services-logic-app/template.json)