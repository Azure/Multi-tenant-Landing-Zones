if (!$workingDir) {
    $workingDir = $PSScriptRoot;
}

if (!$workingDir) {
    $workingDir = (Get-Location).Path
}

$manifestPath = Join-Path (Split-path $workingDir) "cmdb" 
$manifest = Get-ChildItem -recurse -path $manifestPath -filter manifest.json
$manifest | Foreach-Object {
    $customerName = $_.Directory.Name
    $file = $_.FullName;
    Describe "[$customerName] validation" {
        $manifestJson = Get-Content $file -Raw -ErrorAction SilentlyContinue
        $manifest = ConvertFrom-Json -InputObject $manifestJson -ErrorAction SilentlyContinue

        Context 'File Validation' {
            It 'Template ARM File Exists' {
                Test-Path $file -Include '*.json' | Should -Be $true
            }

            It 'Is a valid JSON file' {
                $manifestJson | ConvertFrom-Json -ErrorAction SilentlyContinue | Should -Not -Be $Null
            }
        }
        # Context 'File Content Validation' {
        #     It "Contains all required elements" {
        #         $Elements = 'artifacts',
        #                     'defaultDeploymentScope'|Sort-Object                                                      
        #         $templateProperties = $manifest | Get-Member -MemberType NoteProperty | Sort-object -property Name| ForEach-Object Name
        #         $templateProperties | Should -Be $Elements
        #     }
        #     It "Artifacts have required elements" {
        #         $Elements = 'tenant',
        #                     'managementGroups',
        #                     'subscriptions',
        #                     'resourceGroups',
        #                     'blueprints'|Sort-Object                                                     
        #         $templateProperties = $manifest.artifacts | Get-Member -MemberType NoteProperty |Sort-object -property Name| ForEach-Object Name
        #         $templateProperties | Should -Be $Elements
        #     }
        # } 
        # To do - add artifact validation (correct type, name, case-sensitivity matching and scope)
        
    }
}