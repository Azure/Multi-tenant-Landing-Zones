[CmdletBinding()]
# Upload template to container
param($storageAccountName, $storageAccountKey, $version="1.0", $artifactsPath);

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


if(!$artifactsPath){
    $artifactsPath ="./src/platform-automation/artifacts/"
    if($PSScriptRoot){
        $artifactsPath = Join-Path (Split-path $PSScriptRoot) "artifacts"
    } else {
        $artifactsPath = "./src/platform-automation/artifacts/"
    }    
}

function Get-Storage {
    [CmdletBinding()]
    param($storageAccountName, $storageAccountKey, $location="westeurope")

    Write-Verbose "[-]Initiatlize storage"
    $storageAccount = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey;   
    if(!$? -or !$storageAccount){
        Write-Verbose "[FAIL]-Storage account for artifacts does not exist!"
        exit 1
    }
    
    Write-Verbose "[OK]Storage account"
    return $storageAccount
}
Function Create-Container ($storage, $containerName){
    Write-Verbose "[-]Create-Container $containerName"
    $container = Get-AzStorageContainer -Name $containerName -Context $storage.Context -ErrorAction SilentlyContinue;
    if(!$container){
        Write-Verbose "   Creating storage container $containerName"    
        $container = New-AzStorageContainer -Name $containerName -Context $storage.Context -Permission Container;
    } 
    Write-Verbose "[OK]Create-Container $containerName"
    return $container;
}

# Takes every subfolder of a given folder (maps it to container)
# For each file/subfolder of subfolder -> upload to blob
function Upload-ArtifactsFromFolder {    
[CmdletBinding()] 
param($storage, $artifactsPath, $version="1.0")
    # Upload files
    Write-Verbose "[-]Upload artifacts from folder $artifactsPath"
    $artifactTypes = Get-ChildItem -Path $artifactsPath -Directory; 
    $artifactTypes|Foreach-Object {
        $artifactType = $_.Name.ToLower()
        $container = Create-Container -storage $storage -containerName $artifactType

        
        # Todo - quick fix - handle seperate per type
        if($artifactType -eq "dashboards" -or $artifactType -eq "dsc" -or $artifactType -eq "policy-definitions" -or $artifactType -eq "scripts" -or $artifactType -eq "workbooks"){
            
        }    
        elseif($artifactType -eq "blueprints"){
            $bps = Get-ChildItem -Path $_.FullName -Directory; 
            $bps|Foreach-object {
                $zippedBp = $_.FullName + "-$($version).zip"  
                Compress-Archive -Path $($_.FullName+"/*") -DestinationPath $zippedBp
                $name = $_.Name + "-$($version).zip" 
                Write-Verbose "   Uploading file $zippedBp to $name"
                $result=Set-AzStorageBlobContent -Container $artifactType -Context $storage.Context -File $zippedBp -Blob $name -Force;
                Remove-Item -Path $zippedBp
            }
        } else {

            # Artifacts (templates)
            $files = Get-childitem -Path $_.FullName -Filter "*.json" -Recurse;        
            if($files -and $files.length -gt 0){
                $files|Foreach-object {
                    $parentDirectory = $_.Directory.Parent;
                    if($_.FullName.IndexOf($artifactType) -gt -1){
                        $basePath = $artifactType+[System.IO.Path]::DirectorySeparatorChar;
                        $name = $_.FullName.Substring($_.FullName.IndexOf($basePath)+$basePath.length);        
                        # Make sure name is 'normalized' for storage
                        $name = "$($name.replace([System.IO.Path]::DirectorySeparatorChar,"/"))";                          
                        
                        $lastPart = $name.Substring($name.LastIndexOf("/")+1);
                        $firstPart = $name.Substring(0, $name.LastIndexOf("/"));
                        if($lastPart.Contains(".parameters.json")){
                            $lastPart = $lastPart.replace('.parameters.json', "-$($version).parameters.json")
                        } else {
                            $lastPart = $lastPart.replace('.json', "-$($version).json")
                        }
                        
                        $name = "$firstPart/$lastPart";               
                        Write-Verbose "   Uploading file $($_.FullName) to $name"
                        $result=Set-AzStorageBlobContent -Container $artifactType -Context $storage.Context -File $_.FullName -Blob $name -Force;
                    } 
                }    

            }
        }
    }
    Write-Verbose "[OK]Upload artifacts"
}

$storage = Get-Storage -storageAccountName $storageAccountName -storageAccountKey $storageAccountKey
Upload-ArtifactsFromFolder -storage $storage -artifactsPath $artifactsPath -version $version