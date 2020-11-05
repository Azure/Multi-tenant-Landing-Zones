Import-Module '/arm-ttk/arm-ttk/arm-ttk.psd1'

$params = @{};

if($env:TestsToInclude){
     $params.Add("Test", $env:TestsToInclude);
}
if($env:TestsToSkip){
    $params.add("Skip", $env:TestsToSkip)
}


if($env:TemplatePath -and -not $env:TemplatesFolder){
    $params.Add("TemplatePath", $env:TemplatePath);
}

$testRuns = @();

if($env:TemplatesFolder){
    $files = Get-ChildItem -Recurse -filter *.json -path $env:TemplatesFolder -exclude *.parameters.json;
    $files | Foreach-object {
        $TestResults = Test-AzTemplate @params -TemplatePath $_.FullName;
        $testRuns += $TestResults;
    }
} else {
    $TestResults = Test-AzTemplate @params;    
    $testRuns += $TestResults;
}

$runs = $testRuns|foreach-object {
    @{
        "Passed"=$_.Passed;
        "Name"=$_.Name;
        "Group"=$_.Group;
        "FileName"=$_.File.FullPath;
        "FileshortName"=$_.File.Name;
        "Output" = $_.AllOutput;     
    }
}
$TestFailures = $runs | Where-Object { -not $_.Passed }

# Write test results to csv file (output path) 
if($env:OutputFilePath){    
    $outputPath = $env:OutputFilePath;
    if(!(Test-Path $outputPath)){
        [void](New-Item -ItemType File $outputPath -force);
    }  
    $runs|ConvertTo-Csv -Delimiter ';'|Set-Content $outputPath;
}

$runs|Select-Object FileName, Group, Passed, Name, Output;

# Fail github
if ($TestFailures) {    
    Write-Error "There were $($TestFailures.Count) tests failing - please fix before continuing!" 
    $TestFailures|Select-Object FileName, Group, Passed, Name, Output;
    Write-Error "There were $($TestFailures.Count) tests failing - please fix before continuing!"
    exit 1
} 

else {
    Write-Output "All tests are passing" 
    exit 0
}