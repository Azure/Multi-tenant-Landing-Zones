param($secretJson)
$ds=$secretJson|ConvertFrom-Json
if(!(Get-Command Add-AzAccount -ErrorAction SilentlyContinue)){
    Write-Verbose "Installing Powershell AZ Module"
    $null = Find-Module -Name Az | Install-Module -Force
}
if(!(Get-Command Import-AzBlueprintWithArtifact -ErrorAction SilentlyContinue)){
    Write-Verbose "Installing Powershell AZ Blueprints Module"
    $null = Find-Module -Name Az.Blueprint | Install-Module -Force
}
$secpasswd = ConvertTo-SecureString $ds.clientSecret -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($ds.clientId, $secpasswd)
Add-AzAccount -ServicePrincipal -Credential $Credential -Tenant $ds.TenantId    
# if we have CLI make sure we log in with that one as well
if(Get-Command az){
    # Login with AZ as well
    az login --service-principal --username $ds.ClientId --password $ds.clientSecret --tenant $ds.TenantId
}