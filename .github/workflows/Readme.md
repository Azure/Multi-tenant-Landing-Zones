# Workflows needs to be on (ROOT)\.github\workflows

# Getting started
The workflows needs some secrets to be set under github and some 'prework'. 

Create a storage account that are to be used for sharing artifacts (or configure the name in the pipelines)
See:
 - [Publish-Artifacts-To-AzureStorage.yml](./Publish-Artifacts-To-AzureStorage.yml).
 - [Deploy-Contoso.yml](./Deploy-Contoso.yml).

Create minimum two secrets in github to allow the 'operations/platform' pipelines to work: 
 
 - AZURE_DEPLOYMENT_STORAGE_SAS => SAS from the previous storage account
 - AZURE_SUBSCRIPTION_CREDENTIAL => Credential for deployment automation 
 
 In addition - per pipeline (customer) 
 - AZURE_CUSTOMER_SUBSCRIPTION_CREDENTIAL => Diff
