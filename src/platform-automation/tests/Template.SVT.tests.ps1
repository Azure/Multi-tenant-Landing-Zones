install-module AzSK;

# https://azsk.azurewebsites.net/03-Security-In-CICD/Readme.html#execute-arm-template-checker-in-baseline-mode
if(!$workingDir){
    $workingDir = $PSScriptRoot;
}

if(!$workingDir){
    $workingDir = (Get-Location).Path
}

#$templateToTest  = Join-Path (Join-Path (Split-path $workingDir) "artifacts") -childPath "templates\subscription\Security-Center.json"

$templateToTest  = Join-Path (Join-Path (Split-path $workingDir) "artifacts") "templates"
$testScriptPath  = Join-Path (Join-Path (Split-path $workingDir) "platform-scripts\Helpers") -childPath "Invoke-AzSKARMTemplateSecurityStatusPesterTest.ps1"

Invoke-Pester -Script @{ Path = $testScriptPath; Parameters = @{ TemplatePath = $templateToTest; Recurse = $true }}

