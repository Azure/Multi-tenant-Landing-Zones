#Requires -Modules @{ModuleName="Az.Resources";ModuleVersion="2.2.0"}  
#Requires -Modules @{ModuleName="Az.Storage";ModuleVersion="2.2.0"} 
#Requires -Modules @{ModuleName="Az.Blueprint";ModuleVersion="0.2.10"}  
[cmdletbinding()]
param(      
      $customer="contoso",      
      $storageAccountName,    
      $storageAccountKey,      
      $customerPath,     
      $deploymentFile="manifest.json",
      # If specified DryRun - will run deployments with -WhatIf and capture diff into ChangeLogFile ([System.Management.Automation.SwitchParameter]::Present
      [Parameter(ParameterSetName='DryRun')]      
      [switch]$dryRun,
      [Parameter(ParameterSetName='DryRun')]
      [string]
      $changelogFile
)

$workingDir = $PSScriptRoot;

<#
    Todo : Two improvements to add:

   - Enable Script callouts per customer (pre/post)
   - Save to local folder & deploy from local folder (e.g. export files & create deploy script) - for scenarios to 'bring to customer' standalone (to simplify process)
#>

if(!$PSScriptRoot){
    $workingDir = (Get-Location).Path
}

# Fallbacks to enable testing locally easy

if(!$storageAccountKey -and $env:StorageAccountKey){
    $storageAccountKey = $env:StorageAccountKey
}

if(!$storageAccountName -and $env:storageAccountName){
    $storageAccountName = $env:storageAccountName
}

if(!$storageAccountKey){
    Write-Error "You need storage account key to continue"
    exit 1;
}

$storageAccount = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey;   
if(!$? -or !$storageAccount){
    Write-Verbose "[FAIL]-Storage account for artifacts does not exist!"
    exit 1
}

# . INCLUDE files
$helperScript  = (Join-Path (Join-Path "$workingDir" "Helpers") "Deployment-builder.ps1")
. "$helperScript" -storageAccount $storageAccount
$bpHelperScript  = (Join-Path (Join-Path "$workingDir" "Helpers") "Deployment-blueprints.ps1")
. "$bpHelperScript"
# END INCLUDE

if(!$customerPath){        
    $customerPath = Join-Path (Join-Path (Split-path $workingDir) "cmdb") "customers"    
}

$customerRootPath = (Join-Path $customerPath $customer)
$manifestJson = Join-path $customerRootPath $deploymentFile

Write-Verbose "[-]Deploy customer $customer"

if(!(Test-Path $manifestJson)){
    Write-Error "[FAIL]-Deploy customer - $manifestJson does not exist"
    exit 1;
}

$data  = Get-Content $manifestJson|ConvertFrom-Json 
if(!$?){
    Write-Error "[FAIL]-Deploy customer - Invalid JSON"

}


function Get-BlobAndUri {
    [cmdletbinding()]    
    param($storage, $blobName, $containerName, $containerToken)
    Write-Verbose "Get blob $blobName from $containerName"
    $blob = Get-AzStorageBlob -Blob "$blobName" -Container $containerName -Context $storage.Context -ErrorAction SilentlyContinue        
    $fullUri = "";
    if($blob){        
        $fullUri = "$($blob.ICloudBlob.uri.AbsoluteUri)$($containerToken)"        
    } else {
        $blob = $false;
    }
    return ($blob, $fullUri)

}


function Switch-DeploymentContext {
    [cmdletbinding()]
    param($tenantId, $subscription)

    if($tenantId -and $tenantId -ne ""){
        # Need to handle explicit different tenants
        Write-Verbose "Setting default context for customer deployment: $tenantId"
    }
    
    return (Select-AzSubscription $subscription)
    # Assuming logged in to correct tenant for now (As Lighthouse does not allow delegation on management group and subscription is minimum 'scope' for multi-tenant deploy)
    # return (Set-AzContext -Tenant $tenantId -Subscription $subscription)        
}

function Deploy-Scope {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('tenant','managementgroup','subscription','resourcegroup')]
        $scope, 
        $deployments, 
        $containerName="templates",        
        $containerToken,
        $defaultDeploymentScope
        )
        
        [void](Switch-DeploymentContext -tenantId $defaultDeploymentScope.tenantId -subscription $defaultDeploymentScope.subscription)

        if(!$?){
            Write-Error "Unable to set and use scoped context."
            exit 1;
        }
        Write-Verbose "[---]Deploy artifacts on $scope"

        $artifacts=$deployments|Get-Member -type NoteProperty
        
        if(-not $artifacts -or $artifacts.length -lt 1 -or -not $artifacts.name){
            Write-Verbose "There are no artifacts in this scope"
            return $true
        }
        
        $results = $artifacts.Name|ForEach-Object {
            $key = $_
            $deployment = $deployments."$key";            
            if($deployment.scope){
                Write-Verbose "[----][$key] $($deployment.name) $($deployment.version) Scope.Name: $($deployment.scope.name)"             
            } else {
                Write-Verbose "[----][$key] $($deployment.name) $($deployment.version) Scope.Name <Auto resolve>"            
            }            
            if($deployment.ErrorAction){
                $ea = $deployment.ErrorAction;
            } else {
                $ea = $ErrorActionPreference
            }
            $templateName = "$scope/$($deployment.name)-$($deployment.version).json"
            $blobParamsName = "$scope/$($deployment.name)-$($deployment.version).parameters.json"        
            $blob, $templateFile = Get-BlobAndUri -storage $storageAccount -blobName $templateName -containerName $containerName -containerToken $containerToken
            
            # Normalize the params-path
            # Has Subfolder 
            $paramsFileName = "$($deployment.name).parameters.json"
            $paramsRootFolder = (Join-Path $customerRootPath $scope)
            if($deployment.Name.IndexOf('/') -gt -1){
                $extraPath = $deployment.Name.Substring(0, $deployment.Name.LastIndexOf('/')).Replace('/', [System.IO.Path]::DirectorySeparatorChar);                
                $paramsRootfolder = Join-Path $paramsRootFolder $extraPath
                Write-Verbose "Params root folder $paramsRootFolder"                
                $paramsFileName = $deployment.Name.Substring($deployment.Name.LastIndexOf('/')+1) + ".parameters.json"
                Write-Verbose "Checking for $paramsFileName"                 
            } 

            $customerParamsFile = Join-Path $paramsRootFolder "$($key).$($paramsFileName)"    
                        
            if(!$templateFile){
                Write-Error "Artifact does not exist in gallery with this version"
                break;
            }
            $deploymentParams = @{
                "TemplateUri" = $templateFile
            }
        
            if((Test-Path $customerParamsFile)){
                Write-Verbose "Using customer params file [$customerParamsFile]"
                $deploymentParams.Add('TemplateParameterFile',$customerParamsFile)                
            } else {
                $blobParams, $templatesParamUri = Get-BlobAndUri -storage $storageAccount -blobName $blobParamsName -containerName "templates" -containerToken $containerToken        
                if($blobParams){
                    $deploymentParams.Add('TemplateParameterUri',$templatesParamUri)                                    
                } else {
                    Write-Warning "-----Unable to resolve a params file for deployment - deployment might fail if there's required params"
                }
            } 
            
            $deploymentName = Get-DeploymentNameForKey -key $key -deployment $deployment
            
            $deploymentParams.Add('Name',$deploymentname)
            
            if($dryRun.IsPresent){
                $deploymentParams.Add('WhatIf',[System.Management.Automation.SwitchParameter]::Present)
            }
            # Location is needed for most scopes 
            $location= $defaultDeploymentScope.location
            if($deployment.scope){
                if($deployment.scope.location){
                    $location= $deployment.scope.location
                }   
            }
            # Write-Verbose "Does customer have deployment-override script?"
            # Improvement / Todo : For more flexible and advanced scenario - could call out to script
            # Custom hooks (pre/post deployment) for e.g. manipulating params before / after             
            # Passing $deploymentParams + +token + $scope into script
            
            switch ($scope) {
                'tenant' {
                    if($deployment.scope){
                        Write-Error "Support for multiple tenant deployments for 1 customer is not implemented - scoped to 1 tenant / customer"               
                    }
                    if($dryRun.IsPresent){
                        Write-Output "WhatIf is not supported for tenant deployment yet."
                    } else {
                        $result = New-AzTenantDeployment @deploymentParams -Location $location -ErrorAction $ea 
                        $result;
                    }                                                                        
                }
                'managementgroup' {
                    if($deployment.scope -and $deployment.scope.name){                    
                        $managementgroup = Get-AzManagementGroup -GroupName $deployment.scope.name                        
                    } else {
                        Write-Verbose "Using default (first) management scope"
                        $managementgroup = (Get-AzManagementGroup)[0]
                    }       
                    if($dryRun.IsPresent){
                        Write-Output "WhatIf is not supported for management group deployment yet."
                    } else {                         
                        $deploymentParams.Add("ManagementGroupId", $managementgroup.Name)
                        $result = New-AzManagementGroupDeployment @deploymentParams -location $location -ErrorAction $ea;
                        $result;
                    }                    
                }
                'subscription' {
                    if($deployment.scope -and $deployment.scope.id){
                        Switch-DeploymentContext -tenantId $defaultDeploymentScope.tenantId -subscription $deployment.scope.id                
                    } else {
                        Write-Verbose "Using default subscription"
                    }                
                    $result = New-AzSubscriptionDeployment @deploymentParams -Location $location -ErrorAction $ea;
                    $result;
                }
                'resourcegroup' {
                    if($deployment.scope -and $deployment.scope.name) {
                        $deploymentParams.Add("ResourceGroupName", $deployment.scope.name)
    
                        if($deployment.scope.subscription -and ($deployment.scope.subscription)){
                            Switch-DeploymentContext -tenantId $defaultDeploymentScope.tenantId -subscription $deployment.scope.subscription
                        }
                        $result = New-AzResourceGroupDeployment @deploymentParams -ErrorAction $ea;
                        $result;
                    } else {
                        Write-Error "[FAIL]-Resource group deployment missing scope (name)"
                    }     
                }                
                Default {}
            }                               
        }
 }

$defaultScope = $data.defaultDeploymentScope

Write-Output "[--]Getting templates token"
$containerToken = New-AzStorageContainerSASToken -Context $storageAccount.Context -container "templates" -Permission "r" -ExpiryTime (Get-Date).AddHours(2)

## Assert that artifacts are valid before deploying any of them
$isValid, $validationErrors = Assert-ThatArtifactsAreAllowed -artifacts $data.artifacts;

if($isValid){
    ## ARM DEPLOYMENTS 
    $tenantDeployments = Deploy-Scope -scope 'tenant' -deployments $data.artifacts.tenant -containerName 'templates' -containerToken $containerToken -defaultDeploymentScope $defaultScope
    $managementGroupDeployments  = Deploy-Scope -scope 'managementgroup' -deployments $data.artifacts.managementGroups -containerName 'templates' -containerToken $containerToken -defaultDeploymentScope $defaultScope
    $subscriptionDeployments  = Deploy-Scope -scope 'subscription' -deployments $data.artifacts.subscriptions -containerName 'templates' -containerToken $containerToken -defaultDeploymentScope $defaultScope
    $resourceGroupDeployments = Deploy-Scope -scope 'resourcegroup' -deployments $data.artifacts.resourceGroups -containerName 'templates' -containerToken $containerToken -defaultDeploymentScope $defaultScope
    ## END ARM deployments    
}

## BLUEPRINTS
$containerbpToken = New-AzStorageContainerSASToken -Context $storageAccount.Context -container "blueprints" -Permission "rwdl" -ExpiryTime (Get-Date).AddHours(2)
Deploy-Blueprints -deployments $data.artifacts.blueprints -containerName 'blueprints' -containerToken $containerbpToken -defaultDeploymentScope $defaultScope

Write-Output "[OK]-Deployment finished"
