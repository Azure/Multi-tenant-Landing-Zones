<#PSScriptInfo
.VERSION 1.0.0
.GUID bf41177f-4d1e-481a-a126-5f0c07dd9aae
.AUTHOR Daniel Scott-Raynsford
.COMPANYNAME
.COPYRIGHT (c) 2018 Daniel Scott-Raynsford. All rights reserved.
.TAGS AzSK, Pester, Test
.LICENSEURI https://gist.github.com/PlagueHO/1af35ee65a2276ca90b3a8a5b224a5d4
.PROJECTURI https://gist.github.com/PlagueHO/1af35ee65a2276ca90b3a8a5b224a5d4
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES First version.
.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core
#>

#requires -Modules @{ ModuleName="AzSK"; ModuleVersion="3.6.1" }
#requires -Modules @{ ModuleName="Pester"; ModuleVersion="4.3.0" }
<#
	.SYNOPSIS
	Pester test for validating ARM template meets best-practices

	.DESCRIPTION
	This Pester test will validate one or more ARM templates in the specified
	file path to validate that they meet the best practices.

	.PARAMETER TemplatePath
	The full path to the ARM template to check. This may be a path with
	wild cards to check multiple files.

	.PARAMETER Severity
	An array of severity values that will count as failed tests. Any violation
	found in the ARM template that matches a severity in this list will cause
	the Pester test to count as failed. Defaults to 'High' and 'Medium'.

	.PARAMETER SkipControlsFromFile
	The path to a controls file that can be use to suppress rules.
#>
[CmdletBinding()]
param (
	[Parameter(Mandatory = $true)]
	[System.String]
	$TemplatePath,

	[Parameter()]
	[System.String[]]
	$Severity = @('High','Medium'),

	[Parameter()]
	[System.String]
	$SkipControlsFromFile
)

Describe 'ARM template best practices' -Tag 'AzSK' {
	Context 'When AzSK module is installed and run on all files in the Templates folder' {
		$resultPath = Get-AzSKARMTemplateSecurityStatus `
			-ARMTemplatePath $TemplatePath `
			-Preview:$true `
			-DoNotOpenOutputFolder `
			-SkipControlsFromFile $SkipControlsFromFile `
			-Recurse
		$resultFile = (Get-ChildItem -Path $resultPath -Filter 'ARMCheckerResults_*.csv')[0].FullName

		It 'Should produce a valid CSV results file ' {
			$resultFile | Should -Not -BeNullOrEmpty
			Test-Path -Path $resultFile | Should -Be $true
			$script:resultsContent = Get-Content -Path $resultFile | ConvertFrom-Csv
		}

		$groupedResults = $script:resultsContent | Where-Object -Property Status -EQ 'Failed' | Group-Object -Property Severity

		$testCases = $Severity.Foreach({@{Severity = $_}})

		It 'Should have 0 failed Severity:<Severity> results' -TestCases $testCases {
			param ( [System.String] $Severity )
			$failedCount = $groupedResults.Where({ $_.Name -eq $Severity })[0].Count
			$failedCount | Should -Be 0
		}
	}
}
