## Navigation Menu
* [Getting started](../../platform-automation#platform-automation---getting-started)
* [Landing zones](../../../docs/Landing-zones.md)
    -	[Artifacts](../../../docs/Artifacts.md)
    -   **Customers**
    -	[Multi tenant deployments](../../../docs/Multi-tenant-deployments.md)
* [Platform automation at scale](../../../docs/Platform-automation-at-scale.md)
* [Design Guidelines](../../../docs/Design-Guidelines.md)
    -	[CSP and Azure AD Tenants](../../../docs/CSP-and-Azure-AD-Tenants.md)
    -	[Identity, Access Management and Lighthouse](../../../docs/Identity-Access-Management-and-Lighthouse.md)
    -	[Management Group and Subscription Organisation](../../../docs/Management-Group-and-Subscription-Organisation.md)
    -	[Management and Monitoring](../../../docs/Management-and-Monitoring.md)
    -	[Security, Governance and Compliance](../../../docs/Security-Governance-and-Compliance.md)
    -	[Platform Automation and DevOps](../../../docs/Platform-Automation-and-DevOps.md)
---


# Customers 
Each subfolder under customers represents a customer that should be deployed. Each customer will have a list of the artifacts for deployment.


Add parameter overloads for artifacts at the right level by creating a structure with parameters files. 

# Structure for customer deployment


    |-- Customer (Root)  
        |-- artifacts.json  
        |-- tenant (scope)  
            |--DeploymentKey.DeploymentName.parameters.json 
            |--DeploymentKey2.DeploymentName.parameters.json  
        |-managementGroup (scope)  
            |--DeploymentKey.DeploymentName.parameters.json  
        |-subscriptions (scope)  
            |--DeploymentKey.DeploymentName.parameters.json  
            |--DeploymentKey2.DeploymentName.parameters.json  
        |-resourceGroup (scope)  
            |--DeploymentKey.DeploymentName.parameters.json  
            |--DeploymentKey2.DeploymentName.parameters.json 


