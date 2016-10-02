Configuration fileserver
{
 
[CmdletBinding()]
 
Param (
    [string] $NodeName,
    [string] $domainName,
    [System.Management.Automation.PSCredential]$domainAdminCredentials
)
 
Import-DscResource -ModuleName PSDesiredStateConfiguration, XComputerManagement, xSmbShare, xdfs
 
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
        		FullAccess                = "everyone"
        		PsDscRunAsCredential      = $domainAdminCredentials
        	}
     		        
		 WindowsFeature DFS
        {
            Name = 'FS-DFS-Namespace'
            Ensure = 'Present'
			DependsOn  = "[xSmbShare]myshare"
        }

       
     }

}

Configuration fileserver2
{
 
[CmdletBinding()]
 
Param (
    [string] $NodeName,
    [string] $domainName,
    [System.Management.Automation.PSCredential]$domainAdminCredentials
)
 
Import-DscResource -ModuleName PSDesiredStateConfiguration, XComputerManagement, xSmbShare, xdfs
 
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
        		FullAccess                = "everyone"
        		PsDscRunAsCredential      = $domainAdminCredentials
        	}
     		        
		 WindowsFeature DFS
        {
            Name = 'FS-DFS-Namespace'
            Ensure = 'Present'
		}

		xDFSNamespaceRoot DFSNamespaceRoot_Domain_DepartmentA
        {
            Path                 = '\\contoso.com\departments'
            TargetPath           = '\\fileserver\myshare'
            Ensure               = 'present'
            Type                 = 'DomainV2'
            Description          = 'AD Domain based DFS namespace for storing departmental files'
            TimeToLiveSec        = 600
            PsDscRunAsCredential = $domainAdminCredentials
			DependsOn            = "[WindowsFeature]DFS"
        } 

		xDFSNamespaceRoot DFSNamespaceRoot_Domain_DepartmentB
        {
            Path                 = '\\contoso.com\departments'
            TargetPath           = '\\fileserver2\myshare'
            Ensure               = 'present'
            Type                 = 'DomainV2'
            Description          = 'AD Domain based DFS namespace for storing departmental files'
            TimeToLiveSec        = 600
            PsDscRunAsCredential = $domainAdminCredentials
			DependsOn            = "[xDFSNamespaceRoot]DFSNamespaceRoot_Domain_DepartmentA"
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
