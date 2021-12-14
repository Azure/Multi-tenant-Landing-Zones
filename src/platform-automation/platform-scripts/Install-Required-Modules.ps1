if(!(Get-Command Add-AzAccount -ErrorAction SilentlyContinue)){
    Write-Verbose "Installing Powershell AZ Resources Module"
    $null = Find-Module -Name Az.Resources | Install-Module -Force
}
if(!(Get-Command Import-AzBlueprintWithArtifact -ErrorAction SilentlyContinue)){
    Write-Verbose "Installing Powershell AZ Blueprints Module"
    $null = Find-Module -Name Az.Blueprint | Install-Module -Force
}
if(!(Get-Command New-AzStorageContext -ErrorAction SilentlyContinue)){
    Write-Verbose "Installing Powershell AZ Storage Module"
    $null = Find-Module -Name Az.Storage | Install-Module -Force
}