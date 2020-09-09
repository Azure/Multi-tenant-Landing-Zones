param(
    [Parameter(Mandatory=$true)]
    $storageAccount
)
# Return a list of artifacts allowed at scope - based on what has been published
function Get-AllowedTemplateArtifacts {
    [cmdletbinding()]
    param()

    $scopes = @('tenant','resourcegroup', 'managementgroup', 'subscription','resourcegroup');
    $containerName = "templates"    
    $blobs = Get-AzStorageBlob -Container $containerName -Context $storageAccount.Context;
    return $scopes|ForEach-Object {
        $scopeName = $_;
        $templates = $blobs|Where-Object { $_.Name.StartsWith("$($scopeName)/") -and !$_.Name.EndsWith(".parameters.json")}
        $templates | Foreach-Object {
            $name = $_.Name.Replace("$($scopeName)/","");
            $version = $name.Substring($name.LastIndexOf('-')+1).Replace(".json","");
            $name = $name.Substring(0,$name.LastIndexOf('-'));
            new-object PSCustomObject -property @{
                "Scope"=$scopeName;
                "Name" = $name;
                "Version" = $version;
            }            
        }
    }
}
# Example usage
# $isValid, $list = Assert-ThatArtifactsAreAllowed -artifacts $data.artifacts;
function Assert-ThatArtifactsAreAllowed {
    [cmdletbinding()]
    param($artifacts)
    
    $tenant = $artifacts.tenant|Get-Member -type NoteProperty;
    $managementGroup = $artifacts.managementGroups|Get-Member -type NoteProperty;
    $subscription = $artifacts.subscriptions|Get-Member -type NoteProperty;
    $reosurcegroup = $artifacts.resourcegroups|Get-Member -type NoteProperty;
    
    $allowedArtifacts = Get-AllowedTemplateArtifacts;
    $errorList = New-Object System.Collections.ArrayList;
    @(@("tenant", $tenant), @("managementGroups", $managementGroup), @("subscriptions", $subscription), @("resourcegroups", $reosurcegroup))|ForEach-Object {
        $scope = $_[0]
        $items = $_[1]
        $items|ForEach-Object {
            $key = $_.Name
            $deployment = $artifacts.$scope.$key 
            $isAllowed = $allowedArtifacts|Where-Object { $_.Name -ceq $deployment.name -and $_.version -eq $deployment.version};
            if(!$isAllowed){
                Write-Error "Invalid: Deployment $key (Artifact: $($deployment.name) $($deployment.version)) - : $scope"
                $errorList.Add((new-object PSCustomObject -property @{"Key"=$key; "Version"=$deployment.version; "Name"=$deployment.name; "Scope"=$scope}))
            } else {
                Write-Verbose "Valid deployment $key (Artifact: $($deployment.name)) with $($deployment.version)) - : $scope"
            }        
        }
    }    
    
    # Return tuple false and list of invalid deployments
    if($errorList.length -gt 0){
        return ($false, $errorList);
    } else {
        return ($true, @())
    }
    
}

function Get-DeploymentNameForKey {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        $key,
        [Parameter(Mandatory=$true)]
        $deployment
    )
    
    $name = $deployment.name.Replace('/','.')

    $deploymentName = "$($key)_$($name)-$($deployment.version)"
    if($deploymentName.Length -gt 64){
        Write-Warning "Deploymentname $deploymentName is longer than 64 character"
        Write-Warning "Deployment will probably fail!";
    }
    # Todo - sanetize name (if there's illegal character - should warn)
    # https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/common-deployment-errors
    return $deploymentName;
}
function Get-ArtifactFromDeploymentName {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        $deploymentName,
        [Parameter(Mandatory=$true)]
        [ValidateSet('tenant','managementgroup','subscription','resourcegroup')]
        $scope        
    )   
    
    $firstPartIndex = $deploymentName.IndexOf('_');
    $lastPartIndex = $deploymentName.LastIndexOf('-');
    if($firstPartIndex -lt 1 -or $lastPartIndex -lt 2){
        # Not a valid deployment name (not managed by our system!)
        Write-Verbose "$deploymentName on $scope does not seem to be a valid managed deployment"
        return new-object PSCustomObject -property @{
            "Scope"=$scope;
            "Name" = $deploymentName;
            "Version" = "0.0";
            "Key" = "";
            "Managed"=$false
        }       
    }

    $key = $deploymentName.Split('_')[0];
    $name = $deploymentName.Substring($firstPartIndex+1, $lastPartIndex-1-$firstPartIndex);
    $version = $deploymentName.Substring($lastPartIndex+1);
    return new-object PSCustomObject -property @{
        "Scope"=$scope;
        "Name" = $name;
        "Version" = $version;
        "Key" = $key;
        "Managed"=$true
    }            
}