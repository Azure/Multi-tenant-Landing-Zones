function Deploy-Blueprints {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        $deployments, 
        $containerName="blueprints",        
        $containerToken,
        $defaultDeploymentScope
        )
        
        [void](Switch-DeploymentContext -tenantId $defaultDeploymentScope.tenantId -subscription $defaultDeploymentScope.subscription)

        if(!$?){
            Write-Error "Unable to set and use scoped context."
            exit 1;
        }
        Write-Verbose "[---]Deploy blueprints "

        $artifacts=$deployments|Get-Member -type NoteProperty
        
        if(-not $artifacts -or $artifacts.length -lt 1 -or -not $artifacts.name){
            Write-Verbose "There are no artifacts in this scope"
            return $true
        }

        $artifacts.Name|ForEach-Object {
            $key = $_
            $deployment = $deployments."$key";
            $bpMglocation = $false 
            if($deployment.scope){
                if($deployment.scope.managementGroupID){
                    $bpMglocation = $true
                    Write-Verbose "[----][$key] $($deployment.name) $($deployment.version) BP Location - MG: $($deployment.scope.managementGroupID)"             
                }
                if($deployment.scope.Subscription){
                    $subscription=$deployment.scope.subscription
                }            
            } else {
                $subscription=$defaultDeploymentScope.subscription          
            }
            Write-Verbose "[----][$key] $($deployment.name) $($deployment.version) BP will be assigned to subscription: $subscription."

            if($deployment.ErrorAction){
                $ea = $deployment.ErrorAction;
            } else {
                $ea = $ErrorActionPreference
            }

            $templateName = "$($deployment.name)-$($deployment.version).zip"
            # Add to documentation: BP params file must exist in customer folder     
            $blob, $templateFile = Get-BlobAndUri -storage $storageAccount -blobName $templateName -containerName $containerName -containerToken $containerToken
            
            $paramsFileName = "$($deployment.name).parameters.json"
            $customerBpPath = Join-Path $customerRootPath $containerName

            $customerParamsFile = Join-Path $customerBpPath "$($key).$($paramsFileName)"    
                        
            if(!$templateFile){
                Write-Error "Artifact does not exist in gallery with this version"
                break;
            }

            if($bpMglocation){
                $existentBP = Get-AzBlueprint -ManagementGroupId $deployment.scope.managementGroupID -Name $deployment.Name -Version $deployment.version -ErrorAction $ea                
            } else{
                $existentBP = Get-AzBlueprint -SubscriptionId $deployment.scope.subscription -Name $deployment.Name -Version $deployment.version -ErrorAction $ea
            }
            if($existentBP){
                if($existentBP.version -eq $deployment.version){
                    Write-Output "A bp with same name and version already exists. Assigning existent bp to subscription $subscription."
                    Install-Blueprint -blueprint $existentBP -bpAssignFilePath $customerParamsFile -subscription $subscription 
                    return
                }
            }

            $bpDirectory = New-Item -Type Directory -Name $deployment.Name
            Get-AzStorageBlobContent -Container $containerName -Blob $blob.Name -Context $storageAccount -destination $bpDirectory.fullname
            $zippedBpArtifact = Join-path $bpDirectory.fullname $blob.name
            Expand-Archive -path $zippedBpArtifact -destinationPath $bpDirectory
            Remove-Item -Path $zippedBpArtifact

            Write-Output "Creating blueprint $($deployment.Name) with version $($deployment.version)."
            $bp = Import-BlueprintFromLocation -bpMglocation $bpMglocation -blueprintName $deployment.Name -bpDirectoryPath $bpDirectory.fullname -mgID $deployment.scope.managementGroupID -subscription $subscription -Version $deployment.version
            Install-Blueprint -blueprint $bp -bpAssignFilePath $customerParamsFile -subscription $subscription 
        }

}

function Import-BlueprintFromLocation {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [bool]$bpMglocation,
        $blueprintName, 
        $bpDirectoryPath,        
        $mgID,
        $subscription,
        $version
        )

        # BP can be saved in MG or subscription. If neither is specified in manifest.json, the default subscription will be used
        if($bpMglocation){
            Import-AzBlueprintWithArtifact -Name $blueprintName -ManagementGroupId $mgID -InputPath $bpDirectoryPath -Force
            $importedBp = Get-AzBlueprint -ManagementGroupId $mgID -Name $blueprintName
        } else {
            Import-AzBlueprintWithArtifact -Name $blueprintName -SubscriptionID $subscription -InputPath $bpDirectoryPath -Force
            $importedBp = Get-AzBlueprint -SubscriptionID $subscription -Name $blueprintName
        }
        # success
        if ($?) {
            Write-Output "Imported successfully"
            Publish-AzBlueprint -Blueprint $importedBp -Version $version
        } else {
            throw "Failed to import successfully"
            exit 1
        }
        # Needs to be removed. Added for local testing
        Remove-Item -Path $bpDirectoryPath -recurse
        return $importedBp
}

function Install-Blueprint {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        $blueprint,        
        $bpAssignFilePath,
        $subscription
        )

        # Auto-inserts blueprintId into parameters file
        $content = Get-Content $bpAssignFilePath -raw | ConvertFrom-Json
        $content.properties | ForEach-Object {if($_.blueprintId -ne $blueprint.id){$_.blueprintId=$blueprint.id}}
        $content | ConvertTo-Json -Depth 100| set-content $bpAssignFilePath

        # Assignment name needs to be unique
        $currentDate = (Get-Date).ToString("Dyyyy-MM-ddTHH-mm-ss")
        $bpAssignmentName = "Assignment-$($blueprint.name)-$currentDate"
        New-AzBlueprintAssignment -Name $bpAssignmentName -Blueprint $blueprint -AssignmentFile $bpAssignFilePath -SubscriptionId $subscription 

        # Wait for assignment to complete
        $timeout = new-timespan -Seconds 500
        $sw = [diagnostics.stopwatch]::StartNew()
        while (($sw.elapsed -lt $timeout) -and ($AssignemntStatus.ProvisioningState -ne "Succeeded") -and ($AssignemntStatus.ProvisioningState -ne "Failed")) {
            $AssignemntStatus = Get-AzBlueprintAssignment -Name $bpAssignmentName -SubscriptionId $subscription -ErrorAction SilentlyContinue
            if ($AssignemntStatus.ProvisioningState -eq "failed") {
                Throw "Assignment Failed. See Azure Portal for datails."
                break
            }
        }

        if ($AssignemntStatus.ProvisioningState -ne "Succeeded") {
            Write-Warning "Assignment has timed out, activity is exiting."
        }        
}