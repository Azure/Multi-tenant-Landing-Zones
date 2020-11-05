param($customerDBFile='Customers.csv')
# Simple demo on how to build a customer list and lookup a customer (if we know it) and how we can automatically schedule 
# and build a list of customers we manage.
# Script can be run on regular basis (e.g. 15 minutes) using a SPN with Lighthouse (read access to customers)

## DUE TO BUG IN Powershell cmdlet - this needs to run for now with AZ utils 
if(!(Test-Path $customerDBFile)){
    Write-Error "Customers Database file $customerDBFile is not existing"
    exit 1;
}
if(!(Get-Command az)){
    Write-error "azure cli not existing - cannot continue until Powershell bug is fixed"
    exit 1;
} 



<#  TODO : When powershell module works - and bug is fixed - use the built-in
    $subscriptionsByTenantId = Get-AzSubscription|Group-Object TenantId;
#>

# Simple lookup - assume customers in a csv file 
$customersDB = (Import-CSV $customerDBFile -Delimiter ';');

$subscriptionsByTenantId = az account list | ConvertFrom-Json | Group-Object homeTenantId;
$managedByTenantId = (Get-AZContext).Tenant.Id;
$managedSubscriptions = $subscriptionsByTenantId | ForEach-Object {
    $tenantID = $_.Name;      
    # Filter unknown homeTenant (managed by another account)
    # Or where mangedByTenant == $tenantId
    $customer = $customersDB|Where-Object {$_.TenantId -eq $tenantID}
    if(!$customer){
        $customerName = "Unknown $tenantID"
        $tenantName = "";
    } else {
        $customerName = $customer.CustomerName;
        $tenantName = $customer.TenantName;
    }

    if($tenantID -and $tenantID -ne $managedByTenantId){                    
        $_.Group|ForEach-Object {
            New-Object -TypeName PSCustomObject -Property @{
                    "TenantId" = $tenantID;
                    "TenantName" = $tenantName;
                    # Need for TenantName
                    "CustomerName" = $customerName;
                    "SubscriptionId" = $_.id
                    "SubscriptionState" = $_.State;
                    "SubscriptionName" = $_.name;
            }
        };          
    }        
}|Sort-Object CustomerName


return $managedSubscriptions;