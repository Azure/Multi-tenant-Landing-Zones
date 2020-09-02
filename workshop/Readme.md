# Getting started
This will require you to have understanding of git, installing software and how ARM template works. If you are new to the subject - please read up on the material before starting.

For the setup - we will be using Github - but scripts used in workflows will work for Azure DevOps as well and steps can easily be modified for Azure DevOps. 

## Prepare local dev machine & accounts
The following should be installed on your workstation:

 - VSCode
 - Git cli
 - PowerShell Core
 - Az Module
 - Az CLI
 - Access to Azure subscription as a global admin

## Prepare repository & Azure

- Create a github account if you don't have one already
- Fork this repository
- Create a wiki for the newly forked project
- Clone the two repositories on your local machine

## Create storage account used for artifacts
     
     cd .\src\platform-automation
     Add-Azaccount
     "dev","prod"|Foreach-Object {
        $rg = new-AzResourceGroup -resourcegroupname "rg-$($_)-automation"-location 'west europe'
        $deploy = new-azresourcegroupdeployment -resourcegroup $rg.ResourceGroupName -templateFile .\artifacts\templates\resourcegroup\Storage-Account.json -storageAccountNamePrefix 'devops' -verbose
        # Output names & key     
        Write-Output "$($_) = "
        $deploy.outputs.storageAccountName.value     
        $deploy.outputs.masterKey.value
     }

***Copy the value for storageAccount and masterKey***  - you will need them for Github secrets. 

## Update secrets and variables (Github)
 - Update the workflows 

Replace the value for storageAccountName and paste your value for the following workflows:

    - 

 - Add two github secrets 
    - Secretname: AZURE_DEPLOYMENT_STORAGE_SAS_DEV and AZURE_DEPLOYMENT_STORAGE_SAS_PROD with the respective masterKey values

## Create SPN and add as secret to Github (actions)

### Create SPN (User Access Administrator)
Instructions for how to create an SPN for deployments in customer tenant.

From Azure CLI:

    az ad sp create-for-rbac --name "DevOpsGlobalAdmin" --role 'Owner' --sdk-auth

    You might want to give this SPN User Access Administrator as well to elevate privileges for certain deployments
    You can achieve this by elevating the User Access Administrator and Owner to root level. 

    New-AzRoleAssignment -ApplicationId '<appId>' -RoleDefinitionName 'User Access Administrator' -Scope /
    New-AzRoleAssignment -ApplicationId '<appID' -RoleDefinitionName 'Owner' -Scope /
    
    Your output will be something like this - copy and paste the entire string 

    {
        "clientId": "<<Retracted>>,
        "clientSecret": "<<Retracted>>",
        "subscriptionId": "<<Retracted>>",
        "tenantId": "<<Retracted>>",
        "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
        "resourceManagerEndpointUrl": "https://management.azure.com/",
        "activeDirectoryGraphResourceId": "https://graph.windows.net/",
        "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
        "galleryEndpointUrl": "https://gallery.azure.com/",
        "managementEndpointUrl": "https://management.core.windows.net/"
    }
Copy and paste the entire json string                   

### Create secret for customer deployment
Create a secret called AZURE_SUBSCRIPTION_CREDENTIAL and paste the value from previous step.
*** Note *** When managing multiple customers - replace _SUBSCRIPTION_ with Customername instead. E.g AZURE_CONTOSO_CREDENTIAL - and make sure to refer the right credential in the customer pipeline.

[Github secrets](https://github.com/Azure/actions-workflow-samples/blob/master/assets/create-secrets-for-GitHub-workflows.md)

### Create SPN for Lighthouse management & automation
Repeat the 2 last steps - but create the Lighthouse SPN that you will use for automation for managing customers through Lighthouse. Call the secret AZURE_LIGHTHOUSE_CREDENTIAL in Github actions and paste the value.

## Build your first repeatable building block 

For this exercise - we will focus on secure development practices and building repeatable concepts that you can later deploy. At this point you will not be creating a fully fledged Landing Zone. 

 - Create a seperate branch called 'feature/lz-1'
 - Create your first template under artifacts\templates\resourcegroup\WebApp.json
 - Make sure this is an empty ARM template
 - Validate that the template is valid (Test-AzResourceGroupDeployment)
 - Validate that the template follows the company best practices

```
# Powershell
cd src\platform-automation
.\tests\Templates.tests.ps1   
```
 - Fix potential errors before commiting the file
 - Commit and push your change
 - Verify that the Workflow Test-And-Upload-Dev-Artifacts are running succesfully.
 - From the Azure portal - check that you have gotten a new json file in your storage account targeted for 'dev'
 - Do a pull request onto master 
 - Verify that the Arm-TTK tests are running successfully
 - Merge the changes onto the master branch
 - Verify that the Publish-Artifacts-ToAzureStorage have run succesfully
 - Verify that you now have the template available in your production account ready for use.

Congrats! You now have a succesful pipeline to validate, approve and publish components for re-use!

## Create manifest and provision customer
We will now create a manifest that will be used to bootstrap a tenant (or customer). For the simplicity of this - we focus on the previous building block you created - but remember that deployments can happen on any scope (tenant, management group, subscription or resource group). 

 - Create a new feature branch called 'feature\customer_contoso'
 - Create a new folder under 'cmdb\customers' called 'contoso' 
 - Create an empty manifest.json under cmdb\customers\contoso (see reference)
 - Validate that this manifest is legal

```
# Powershell
cd src\platform-automation
.\tests\Artifacts.tests.ps1   
```
 - Update the settings in the manifest defaultDeploymentScope
 - Test the deployment 

 ```
 cd src\platform-automation
 # Run all deployments with -WhatIf
.\platform-scripts\Deploy-Customer.ps1 -customer 'contoso' -Verbose -DryRun
# Run the manifest with the current session - this will create and update Azure Resources
.\platform-scripts\Deploy-Customer.ps1 -customer 'contoso' -Verbose 
 ```
 - Commit and push the change to your feature branch
 - Verify that the workflow "Update wiki" is running successfully and building the wiki pages for your managed customers. You should be seeing something similar to this:

 [![Wiki](../images/Wiki-main.png)](#)

 - Click on the customers and you should be seeing Contoso listed as one of your customers managed as code:
 [![Wiki](../images/Customers-Overview.png)](#)

 - Do a pull request onto master and merge this request. Verify that the workflow "Deploy-Contoso" runs. This workflow will run anytime anyone have approved changes to be rolled out for Contoso.

## Expanding the Manifest

You will now expand the Manifest. To help you along the way - we have created a few, very simple artifacts for you to build a management structure, do some operations and envision how you can roll out landing zones at scale. Remember - any ARM template can be an artifact and used in composing value. 

- Create a management group structure 
- Move your subscription in under the 'platform' management group
- Modify the lighthouse offer
- Onboard a subscription to your lighthouse offer


- Verify that the Contoso Governance workflow has run (** this workflow builds the details page for Contoso). There's a known limitation in the Mermaid toolkit that is known to hang - so be aware if the workflow executes for more than 10 minutes - you should kill it. 


## Expand with the Sandbox-CAF-Foundation LandingZone

## Resources
#### Creating workflows / Pipelines
[GitHub actions - Docs](https://help.github.com/en/actions/configuring-and-managing-workflows/configuring-a-workflow)

### ARM deployments
- [Management group deployment](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-to-tenant#create-management-group)

### Image packing
https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-automatic-upgrade#automatic-os-image-upgrade-for-custom-images-preview
Packer

