param (
	[Parameter(Mandatory=$true)]
	[string]$TemplatePath 
)

$templateARM = Get-Content $TemplatePath -Raw -ErrorAction SilentlyContinue
$file = Get-ChildItem $templatePath -ErrorAction SilentlyContinue;
$template = ConvertFrom-Json -InputObject $templateARM -ErrorAction SilentlyContinue

if($file){
    $testName = $file.Name;
} else {
    $testName = $TemplatePath
}

Describe "[$testName] validation" {
	Context 'File Validation' {
		It 'Template ARM File Exists' {
			Test-Path $TemplatePath -Include '*.json' | Should Be $true
		}

		It 'Is a valid JSON file' {
			$templateARM | ConvertFrom-Json -ErrorAction SilentlyContinue | Should Not Be $Null
	  }
  }
    Context 'Template Content Validation' {
      It "Contains all required elements" {
          $Elements = '$schema',
                      'contentVersion',
                      'variables',
                      'parameters',
                      'resources',
                      'outputs' | Sort-object                                
            $templateProperties = $template | Get-Member -MemberType NoteProperty | ForEach-Object Name | Sort-object 
            $templateProperties | Should Be $Elements
        }
        <#
        It "Creates the expected resources" {
            $Elements = 'Microsoft.Storage/storageAccounts'
            $templateResources = $template.Resources.type
            $templateResources | Should Be $Elements
        }
        #>
        # Could add a generic validation
        # It "Validates" {
        #    
        # }
    }
}