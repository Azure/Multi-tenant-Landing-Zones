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
 - Verify that the Arm-TTK tests are running
 - Merge the changes onto the master branch
 - Verify that the Publish-Artifacts-ToAzureStorage have run succesfully
 - Verify that you now have the template available in your production account ready for use.

Congrats! You now have a succesful pipeline!

## Create manifest and provision customer
 - Create a new folder under 'customers' called 'Contoso' 
 - Create a manifest.json under customers\contoso
 - Validate that this manifest is 'legal'


## Expand with the Sandbox-CAF-Foundation LandingZone

## Resources
#### Creating workflows / Pipelines
[GitHub actions - Docs](https://help.github.com/en/actions/configuring-and-managing-workflows/configuring-a-workflow)

### ARM deployments
- [Management group deployment](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-to-tenant#create-management-group)

### Image packing
https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-automatic-upgrade#automatic-os-image-upgrade-for-custom-images-preview
Packer

