param($subscriptionFile, [switch]$dryRun)
# Assumes you are logged into partners center before executing
# Just for demo - this is not a working example

if(Test-Path $subscriptionFile){
    $file = Get-ChildItem $subscriptionFile;
    if($file.Name -ne "new_subscription"){
        Write-output "Script triggered on invalid filename - $($file.Name)"
        exit 1;
    }
    
    $folder = $file.Directory
    
    Write-output "Create subscription for $($folder.Name) "
    Write-output "Using AZ Context: $((Get-AZContext).Account.Type) ID: $((Get-AZContext).Account.Id)"    

    if($dryRun.IsPresent){
        Write-output "Would remove $subscriptionFile";
        Write-output "Would create subscription for customer"        
    } else {        
        $name = Get-Content $subscriptionFile;
        Write-output "Remove SubscriptionFile"
        Remove-Item $subscriptionFile;
        $guid = New-Guid;
        Write-output "Creating subscription":
        Write-output "Subscription details"
        Write-output "--------------------"
        Write-output "Id: $guid ";
        Write-output "Name: $name"
    }
    return New-Object -TypeName PSCustomObject -Property @{"Name"=$name; "Id"=$guid};
} else {
    Write-Error "$subscriptionFile does not exist!";
    exit 1;
}

