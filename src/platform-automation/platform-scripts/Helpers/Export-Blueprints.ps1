#Requires -Modules Az
#Requires -Modules Az.Blueprint 
<#
    This module takes all blueprints and exports them to the blueprints artifacts. 
    Typical workflow : build components & templates and do pull request
    Build blueprint - run this script, do pull request on new blueprints     
#>

if($PSScriptRoot){
    $basePath = $PSScriptRoot;
} else {
    $basePath = (Get-Location).Path
}

$basePath = Join-Path (Join-Path (Split-path $basePath) "artifacts") "blueprints"
$blueprints = Get-AzBlueprint
$blueprints|Foreach-object {
    Export-AzBlueprintWithArtifact -Blueprint $_ -Force -Verbose -OutputPath $basePath;
}