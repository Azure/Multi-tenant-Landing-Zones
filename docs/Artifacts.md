## Navigation Menu
* [Getting started](../src/platform-automation#platform-automation---getting-started)
* [Landing zones](./Landing-zones.md)
    -	**Artifacts**
    -   [Customers](../src/platform-automation/cmdb#customers)
    -	[Multi tenant deployments](./Multi-tenant-deployments.md)
* [Platform automation at scale](./Platform-automation-at-scale.md)
* [Design Guidelines](./Design-Guidelines.md)
    -	[CSP and Azure AD Tenants](./CSP-and-Azure-AD-Tenants.md)
    -	[Identity, Access Management and Lighthouse](./Identity-Access-Management-and-Lighthouse.md)
    -	[Management Group and Subscription Organisation](./Management-Group-and-Subscription-Organisation.md)
    -	[Management and Monitoring](./Management-and-Monitoring.md)
    -	[Security, Governance and Compliance](./Security-Governance-and-Compliance.md)
    -	[Platform Automation and DevOps](./Platform-Automation-and-DevOps.md)
---


# Artifacts

Artifacts repository contains all the components a partner will want to deploy. Each artifact type has its own directory. Ex: All the policies will go in the policy-definition folder. For templates, there are 4 deployments scopes: rg, subscription, MG and tenant. 

For instance, if an ARM template needs to be deployed at tenant level, it will be added in templates/ tenant folder. 


    |-- artifacts 
        |-- dashboards 
        |-- dsc 
        |-- pipelines 
        |-- policy-definitions 
        |-- role-definitions 
        |-- scripts 
        |-- templates 
            |-- resourcegroup 
            |-- subscription 
            |-- managementgroup 
            |-- tenant 
        |-- workbooks 

 

An action will be triggered on any commit in artifacts master repo and all artifacts will be added to the storage account used. Once the resources will be stored in the storage account, any combination of those resources can be deployed to any customer. 
