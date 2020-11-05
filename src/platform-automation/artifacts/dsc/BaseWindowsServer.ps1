Configuration BaseWindowsServer
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    
    Node localhost
    { 
        File TempFolderIsPresent
        {
            Ensure = "Present" 
            Type = "Directory"
            Recurse = $true
            DestinationPath = "c:\tmp"
        }
    }
} 