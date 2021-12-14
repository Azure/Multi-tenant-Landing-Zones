param($testName="ValidateTemplates", $testScriptToRun, $testResultsFile)

if(!(Get-Command Invoke-Pester -ErrorAction SilentlyContinue)){
    Write-Verbose "Installing Pester"
    $null = Find-Module -Name Pester | Install-Module -Force
}
# Run with e.g. "Validate templates " tests/Templates.tests.ps1 TestResults.Pester.xml
if (Test-Path $testScriptToRun) {
    $pester = @{
        Script       = $testScriptToRun
        OutputFormat = 'NUnitXml'         
        OutputFile   = $testResultsFile
        PassThru     = $true 
        ExcludeTag   = 'Incomplete'
    }
    $result = Invoke-Pester @pester     
    $result
} else {
 write-error "$testScriptsPath does not exist"
 exit 1;
}