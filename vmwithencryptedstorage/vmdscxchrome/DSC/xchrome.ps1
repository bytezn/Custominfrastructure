Configuration main

{
 
[CmdletBinding()]
 
Param (
    [string] $NodeName,
    [string] $localpath,
    [string] $language

)
 
Import-DscResource -ModuleName xPSDesiredStateConfiguration, XChrome

Node localhost
    {
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyAndAutoCorrect'
            RebootNodeIfNeeded = $true
            ActionAfterReboot = 'ContinueConfiguration'
            AllowModuleOverwrite = $true
        }
 	
    MSFT_xChrome chrome
    {
    Language = $Language
    LocalPath = $LocalPath
    }
        
    }

}