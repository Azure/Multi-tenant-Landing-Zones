param($customersPath="../cmdb/customers", $wikiPath='c:\temp\wiki')
$customers = get-childitem $customersPath -directory;

if(!(Test-Path $wikiPath)){
    New-item -itemtype directory $wikiPath;
}

if(!$PSSCRIPTRoot){
    $path = "./";    
} else {
    $path = $PSSCRIPTRoot;
}

$file = Join-Path $path "/Helpers/Build-ManagedCustomerList.ps1";
$customerDBFile = Join-Path (Split-Path $customersPath) "Customers.csv";
$managedCustomers = . $file -customerDBFile $customerDBFile;
$UniqueManagedCustomers = $managedCustomers|select-object -unique CustomerName;
$customerWikiPage = Join-Path $wikiPath Customers.md
$governanceFolder = 'governance-scan';

#Push-Location $wikiPath;

@"
# Customers overview:
Last update: $(Get-Date) 
Customers: $($customers.count) (as code) / $($UniqueManagedCustomers.Count) (Delegated adminstration through Lighthouse)

"@|Set-Content $customerWikiPage

# Build each customer wiki page
$customers|Foreach-Object {
    $customerName = (Get-Culture).TextInfo.ToTitleCase($_.Name)
    $customerDocFile = "$($customerName).md"
    #if(!(Test-Path -path $customerDocFile)){                  
        $manifestFile = Join-Path (Join-Path $customersPath $_.Name) "manifest.json"
        if((Test-Path $manifestFile)){
            $a = (Get-Content $manifestFile -raw)|Convertfrom-json -asHashTable;
        } else {
            $a = @{"artifacts" = @{"tenant"=@();"managementGroups"=@(); "subscriptions"=@();"resourceGroups"=@()}}
        }
        $governanceBasePath = Join-Path $wikiPath "customers"
        $governanceFolderPath = Join-Path (Join-Path $governanceBasePath $_.Name) $governanceFolder;
        if((Test-Path $governanceFolderPath)){        
            $markdown = Get-ChildItem -Filter *.md -Path $governanceFolderPath;
            if($markdown){
                $pngs = Get-ChildItem -Filter *.png -Path $governanceFolderPath;
                $pngs|ForEach-Object {
                    [void](Copy-Item $_.FullName -Destination $wikiPath)
                }
                $architecture = (Get-Content -raw $markdown) -replace "/wiki/customers/$($_.Name)/governance-scan//","";
                # Remove the original markdown 
                # [void](Remove-item $markdown);
            } else {
                $architecture = "No governance documentation or scan yet";        
            }
        } else {
            $architecture = "No governance documentation or scan yet";        
        }
@"
# $($_.Name) - managed by code
## Artifacts
Deploymentname | Scope | ArtifactName | Version | Latest version     
---------------|-------|--------------|---------|-------------------
 $($a.artifacts.tenant.keys|Foreach-object { 
" $($_) | Tenant | $($a.artifacts.tenant.$_.name) | $($a.artifacts.tenant.$_.version) | . 
"
}
$a.artifacts.managementGroups.keys|Foreach-object { 
" $($_) | ManagementGroup | $($a.artifacts.managementGroups.$_.name) | $($a.artifacts.managementGroups.$_.version) | .
"
}
$a.artifacts.subscriptions.keys|Foreach-object { 
" $($_) | Subscription | $($a.artifacts.subscriptions.$_.name) | $($a.artifacts.subscriptions.$_.version) | .
"
}
$a.artifacts.resourceGroups.keys|Foreach-object { 
" $($_) | ResourceGroup | $($a.artifacts.resourceGroups.$_.name) | $($a.artifacts.resourceGroups.$_.version) | .
"
}
)

## Deployment status (Workflow)
![Customer deployment $($customerName)](https://github.com/haraldfianbakken/NorthStar-Partner/workflows/Customer%20deployment%20$($customerName)/badge.svg)
## Governance scan
$architecture
"@|Set-Content (Join-Path $wikiPath $customerDocFile)

# Add the remaining customers to the overview page
@"
[$($CustomerName)]($($customerDocFile))

"@|Add-Content (Join-Path $wikiPath Customers.md)                            
}

# Managed customers
$content = @"
# Customer delegated subscriptions (Last updated $(Get-Date))

TenantId | Customer Name | SubscriptionId | Subscription Name | Subscription state | Managed as code
---------|---------------|----------------|-------------------|--------------------|-------------------
$(
$managedCustomers|Foreach-Object { 
$customerName = (Get-Culture).TextInfo.ToTitleCase($_.CustomerName)
"[$($_.TenantId)]($($CustomerName))|[$($CustomerName)]($($CustomerName))|$($_.SubscriptionID)|$($_.SubscriptionName)|$($_.SubscriptionState)|$($_.ManagedAsCode)
"
}
)
"@

$content | add-Content $customerWikiPage

#Pop-location;