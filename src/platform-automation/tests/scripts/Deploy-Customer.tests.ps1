if(!(Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue)){
    Write-Verbose "Installing PSScriptAnalyzer"
    $null = Find-Module -Name PSScriptAnalyzer | Install-Module -Force
}

if (!$workingDir) {
    $workingDir = $PSScriptRoot;
}

if (!$workingDir) {
    $workingDir = (Get-Location).Path
}

$scriptsDir = Join-Path (Split-Path (Split-Path $workingDir)) "platform-scripts"
$deployCustomer = Join-Path $scriptsDir 'Deploy-Customer.ps1'
$results = Invoke-ScriptAnalyzer -Path $deployCustomer -Verbose -ExcludeRule 'PSReviewUnusedParameter'
$filteredResults = $results | where-object { $_.Severity -eq 'Warning' -or $_.Severity -eq 'Error' }

if($filteredResults){
    Write-Error "There are errors in test";
    $filteredResults
    exit 1;
}