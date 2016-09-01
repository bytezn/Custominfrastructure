Configuration fileserver
{
 
[CmdletBinding()]
 
Param (
    [string] $NodeName,
    [string] $domainName,
    [System.Management.Automation.PSCredential]$domainAdminCredentials
)
 
Import-DscResource -ModuleName PSDesiredStateConfiguration, XComputerManagement, xSmbShare
 
Node localhost
    {
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyAndAutoCorrect'
            RebootNodeIfNeeded = $true
            ActionAfterReboot = 'ContinueConfiguration'
            AllowModuleOverwrite = $true
        }
 
         WindowsFeature fileservice
        {
            Name = "fileandstorage-services"
            Ensure = "Present"
        } 
         
      	File filename
      	{
      		DestinationPath           = "c:\1\2.txt"
      		Contents                  = "myfile"
      		DependsOn                 = "[WindowsFeature]fileservice"
      		Ensure                    = "Present"
      		Force                     = $true
      		PsDscRunAsCredential      = $domainAdminCredentials
      		Type                      = "File"
      	}
                    
        xSmbShare myshare 
        	{
        		Name                      = "myshare"
        		Path                      = "c:\1"
        		DependsOn                 = "[File]filename"
        		Ensure                    = "Present"
        		FolderEnumerationMode     = "Unrestricted"
        		FullAccess                = "administrator"
        		PsDscRunAsCredential      = $domainAdminCredentials
        	}
     
		   	User lawrance 
          	{
          		UserName                  = "lawrance"
          		DependsOn                 = "[xSmbShare]myshare"
          		Description               = "Lawrance Reddy"
          		Disabled                  = $false
          		Ensure                    = "Present"
          		FullName                  = "lawrance reddy"
          		Password                  = "Master123"
          		PasswordChangeRequired    = $false
          		PasswordNeverExpires      = $true
          		PsDscRunAsCredential      = $domainAdminCredentials
          	}     
     }

}


Configuration Main
{
 
[CmdletBinding()]
 
Param (
    [string] $NodeName,
    [string] $domainName,
    [System.Management.Automation.PSCredential]$domainAdminCredentials
)
 
Import-DscResource -ModuleName PSDesiredStateConfiguration, xActiveDirectory
 
Node localhost
    {
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyAndAutoCorrect'
            RebootNodeIfNeeded = $true
            ActionAfterReboot = 'ContinueConfiguration'
            AllowModuleOverwrite = $true
        }
 
        WindowsFeature DNS_RSAT
        { 
            Ensure = "Present"
            Name = "RSAT-DNS-Server"
        }
 
        WindowsFeature ADDS_Install 
        { 
            Ensure = 'Present'
            Name = 'AD-Domain-Services'
        } 
 
        WindowsFeature RSAT_AD_AdminCenter 
        {
            Ensure = 'Present'
            Name   = 'RSAT-AD-AdminCenter'
        }
 
        WindowsFeature RSAT_ADDS 
        {
            Ensure = 'Present'
            Name   = 'RSAT-ADDS'
        }
 
        WindowsFeature RSAT_AD_PowerShell 
        {
            Ensure = 'Present'
            Name   = 'RSAT-AD-PowerShell'
        }
 
        WindowsFeature RSAT_AD_Tools 
        {
            Ensure = 'Present'
            Name   = 'RSAT-AD-Tools'
        }
 
        WindowsFeature RSAT_Role_Tools 
        {
            Ensure = 'Present'
            Name   = 'RSAT-Role-Tools'
        }      
 
        WindowsFeature RSAT_GPMC 
        {
            Ensure = 'Present'
            Name   = 'GPMC'
        } 
        xADDomain CreateForest 
        { 
            DomainName = $domainName           
            DomainAdministratorCredential = $domainAdminCredentials
            SafemodeAdministratorPassword = $domainAdminCredentials
            DatabasePath = "C:\Windows\NTDS"
            LogPath = "C:\Windows\NTDS"
            SysvolPath = "C:\Windows\Sysvol"
            DependsOn = '[WindowsFeature]ADDS_Install'
        }
    }
}
