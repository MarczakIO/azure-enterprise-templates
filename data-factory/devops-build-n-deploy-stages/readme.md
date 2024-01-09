## Azure Data Factory CI/CD plug-n-play DevOps templates

# Summary
Job templates for building and deploying Azure Data Factory with Azure DevOps

# In Azure DevOps

1. In Azure Data Factory
    1. Setup ADF sync repo in your data factory
       - Recommended to use Root Folder path **/data-factory/** or **/data-factory/<data_factory_name>** if you have many ADFs
    2. Make sure to check **Include global parameters in ARM template** option under **Manage >> ARM template**
2. In Azure DevOps
    1. Create folder **/devops/** and then, in that folder create following files
        1. Create file [package.json](package.json) 
            ```JSON
            {
                "scripts":{
                    "build":"node node_modules/@microsoft/azure-data-factory-utilities/lib/index"
                },
                "dependencies":{
                    "@microsoft/azure-data-factory-utilities":"^1.0.0"
                }
            } 
            ```
        2. Create file [adf-build-job.yml](adf-build-job.yml)
            ```YAML
            parameters:
            - name: subscriptionId 
              type: string 
            
            - name: resourceGroupName 
              type: string
            
            - name: dataFactoryName 
              type: string
            
            - name: repoRootFolder
              type: string
              default: /
            
            - name: packageJsonFolder
              type: string
              default: /
            
            - name: artifactName
              type: string
              default: data-factory
            
            jobs:
            - job: BUILD
              displayName: 'Build ARM Template'
              variables:
                workingDirectory: $(Build.Repository.LocalPath)${{ parameters.repoRootFolder }}
                packageJsonFolder: $(Build.Repository.LocalPath)${{ parameters.packageJsonFolder }}
                dataFactoryResourceId: /subscriptions/${{ parameters.subscriptionId }}/resourceGroups/${{ parameters.resourceGroupName }}/providers/Microsoft.DataFactory/factories/${{ parameters.dataFactoryName }}
                artifactTempDirectory: data-factory-arm
              steps:
              - task: NodeTool@0
                inputs:
                  versionSpec: '14.x'
                displayName: 'Install Node.js'
            
              - task: Npm@1
                inputs:
                  command: 'install'
                  workingDir: $(packageJsonFolder)
                  verbose: true
                displayName: 'Install npm package'
            
              - task: Npm@1
                inputs:
                  command: 'custom'
                  workingDir: $(packageJsonFolder)
                  customCommand: 'run build validate $(workingDirectory) $(dataFactoryResourceId)'
                displayName: 'Validate'
            
              - task: Npm@1
                inputs:
                  command: 'custom'
                  workingDir: $(packageJsonFolder)
                  customCommand: 'run build export $(workingDirectory) $(dataFactoryResourceId) "$(artifactTempDirectory)"'
                displayName: 'Validate and Generate ARM template'        
            
              - task: PublishPipelineArtifact@1
                inputs:
                  targetPath: '$(packageJsonFolder)$(artifactTempDirectory)'
                  artifact: ${{ parameters.artifactName }}
            ```
    2. Create new pipeline under path **/devops/adf-azure-pipelines.yml**, paste in the sample code
        ```YAML
        trigger:
        - main
        
        pool:
          vmImage: ubuntu-latest
        
        stages:
        
        - stage: BUILD
          jobs:
          - template: <path_to_adf-build-job.yml_file>
            parameters:
              subscriptionId: <subscription_id>
              resourceGroupName: <resource_group_name>
              dataFactoryName: <data_factory_name>
              repoRootFolder: <absolute_path_to_datafactory_folder, ex. /data-factory/>
              packageJsonFolder: <absolute_path_to_package_json, ex. /devops/)
        ```
        1. **Replace temp variables** with your env values
    3. Run and test pipeline
    4. In **/devops/** folder create file [adf-deploy-job.yml](adf-deploy-job.yml)
        ```YAML
        parameters:
        - name: environmentName 
          type: string 
        
        - name: serviceConnectionName 
          type: string 
        
        - name: subscriptionId 
          type: string 
        
        - name: resourceGroupName 
          type: string 
        
        - name: dataFactoryName 
          type: string 
        
        - name: artifactName
          type: string
          default: data-factory
        
        - name: overrideParameters
          type: string
          default: 
        
        jobs:
        - deployment: ${{ parameters.environmentName }}
          displayName: Deployment to ${{ parameters.environmentName }}
          variables:
          - name: artifactsDirectory
            value: $(System.ArtifactsDirectory)/data-factory
          environment: '${{ parameters.environmentName }}'
          strategy:
            runOnce:
              deploy:
                steps:
                - script: echo Deploying to ${{ parameters.environmentName }}
                  displayName: 'Script - Display Environment Stage Name'
                  
                - task: DownloadPipelineArtifact@2
                  displayName: 'Download ADF ARM Template'
                  inputs:
                    source: current
                    artifact: ${{ parameters.artifactName }}
                    downloadPath: $(artifactsDirectory)
        
                - script: 'ls $(artifactsDirectory)'
                  displayName: 'List Artifact contents'
        
                - task: AzurePowerShell@5
                  displayName: 'Stop Triggers'
                  inputs:
                    azureSubscription: '${{ parameters.serviceConnectionName }}'
                    ScriptPath: '$(artifactsDirectory)/PrePostDeploymentScript.ps1'
                    ScriptArguments: "-armTemplate $(artifactsDirectory)/ARMTemplateForFactory.json \
                      -ResourceGroupName ${{ parameters.resourceGroupName }} \
                      -DataFactoryName  ${{ parameters.dataFactoryName }} \
                      -predeployment $true \
                      -deleteDeployment $false"
                    azurePowerShellVersion: LatestVersion
        
                - task: AzureResourceManagerTemplateDeployment@3
                  displayName: 'ARM Template deployment'
                  inputs:
                    azureResourceManagerConnection: '${{ parameters.serviceConnectionName }}'
                    subscriptionId: '${{ parameters.subscriptionId }}'
                    resourceGroupName: '${{ parameters.resourceGroupName }}'
                    location: 'Southeast Asia'
                    csmFile: '$(artifactsDirectory)/ARMTemplateForFactory.json'
                    csmParametersFile: '$(artifactsDirectory)/ARMTemplateParametersForFactory.json'
                    overrideParameters: >
                      -factoryName ${{ parameters.dataFactoryName }}
                      ${{ parameters.overrideParameters }}
                            
                - task: AzurePowerShell@5
                  displayName: 'Start Triggers'
                  inputs:
                    azureSubscription: '${{ parameters.serviceConnectionName }}'
                    ScriptPath: '$(artifactsDirectory)/PrePostDeploymentScript.ps1'
                    ScriptArguments: "-armTemplate $(artifactsDirectory)/ARMTemplateForFactory.json \
                      -ResourceGroupName ${{ parameters.resourceGroupName }} \
                      -DataFactoryName ${{ parameters.dataFactoryName }} \
                      -predeployment $false \
                      -deleteDeployment $false"
                    azurePowerShellVersion: LatestVersion
        ```
    5. Navigate to **Project Settings >> Service Connections** and create new connection to Azure using Service Principal and grant at last **Data Factory Contributor** role to all data factories that you will be deploying to
        1. In Azure Portal navigate to Azure Active Directory and create new App Registration
        2. For ADF only piplines grant **Data Factory Contibutor** role on Azure Data Factory resource, or for full CI/CD in Azure grant **Contributor** role to an entire resource group
        2. Copy the details of this service principal and subscription to Azure DevOps
    6. Create Environment (**Pipelines >> Environment**)
    7. Create Variable Group (**Pipelines >> Library >> Variable Groups**)
        1. Add variables that needs to be overriden in ADF template (factoryName is overriden by default)
    8. Edit your **adf-azure-pipelines.yml** pipeline/file and add this stage
        ```YAML
        - stage: <stage_name>
          variables:
          - group: <variable_group_name>
          jobs:
          - template: <path_to_adf-deploy-job.yml_file>
            parameters:
              environmentName: <environment_name>
              subscriptionId: <subscription_id>
              resourceGroupName: <resource_group_name>
              dataFactoryName: <data_factory_name>
              serviceConnectionName: <service_connection_name>
              overrideParameters: >
                -<param_1> <val_1>
        ```
        1. **Replace temp variables** with your env values
    9. Run and test
    10. Add any extra deployment stages you need by repeating steps 5, 6, 7, 8, 9