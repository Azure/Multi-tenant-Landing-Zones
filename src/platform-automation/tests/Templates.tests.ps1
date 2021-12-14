if(!$workingDir){
    $workingDir = $PSScriptRoot;
}

if(!$workingDir){
    $workingDir = (Get-Location).Path
}

$artifactsPath = Join-Path (Join-Path (Split-path $workingDir) "artifacts") "templates"

$files = Get-ChildItem -recurse -path $artifactsPath -filter *.json -exclude *.parameters.json
$files|Foreach-Object {
    $templatePath = $_.Fullname;    
    # Example script for how pester can run for each template    
    $templateARM = Get-Content $TemplatePath -Raw -ErrorAction SilentlyContinue    
    $testName = $_.Name;

    # Ensure JSON files are according to spec 
    # E.g. comments in JSONs are not according to RFC
    Describe "[$testName] template validation" {
        Context 'File Validation' {
            It 'Template ARM File Exists' {
                Test-Path $TemplatePath -Include '*.json' | Should -Be $true
            }
            It 'Is a valid JSON file' {
                $templateARM | ConvertFrom-Json -ErrorAction SilentlyContinue | Should Not -Be $Null
            }
        }
        Context 'Template Content Validation' {
            $template = ConvertFrom-Json -InputObject $templateARM -ErrorAction SilentlyContinue           
            It "Contains all required elements" {
                $Elements = '$schema',
                            'contentVersion',
                            'variables',
                            'outputs',
                            'parameters',
                            'resources'|Sort-object                                
                $templateProperties = $template | Get-Member -MemberType NoteProperty | ForEach-Object Name|Sort-object
                $templateProperties | Should -Be $Elements
            }
            <#
            It "Creates the expected resources" {
                $Elements = 'Microsoft.Storage/storageAccounts'
                $templateResources = $template.Resources.type
                $templateResources | Should Be $Elements
            }
            #>
            # Could add a generic validation - verifying template with Test-AZ*Template
            # It "Validates" {
            #    
            # }
        }
    }
    

}
