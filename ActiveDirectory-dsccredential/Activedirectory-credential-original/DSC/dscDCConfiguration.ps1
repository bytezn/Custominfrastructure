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

		 WindowsFeature DFSMGMT
        {
            Name = "RSAT-DFS-MGMT-CON"
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

Configuration fileserver3
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

		 WindowsFeature DFSMGMT
        {
            Name = "RSAT-DFS-MGMT-CON"
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
            TargetPath           = '\\fileserver3\myshare'
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


Configuration web
{
 
[CmdletBinding()]
 
Param (
    [string] $NodeName,
    [string] $domainName,
    [System.Management.Automation.PSCredential]$domainAdminCredentials
)
 
Import-DscResource -ModuleName PSDesiredStateConfiguration, XComputerManagement, xWebadministration
 
Node localhost
    {
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyAndAutoCorrect'
            RebootNodeIfNeeded = $true
            ActionAfterReboot = 'ContinueConfiguration'
            AllowModuleOverwrite = $true
        }
 	
   		WindowsFeature web 
     	{
 		Name                      = "web-server"
 		Credential                = $domainAdminCredentials
 		Ensure                    = "Present"
 		IncludeAllSubFeature      = $true
    	}
       
	      
        WindowsFeature AspNet45
        {
            Ensure          = "Present"
            Name            = "Web-Asp-Net45"
        }

        xWebsite DefaultSiteStop
        {
            Ensure          = "Present"
            Name            = "Default Web Site"
            State           = "Stopped"
            PhysicalPath    = "C:\inetpub\wwwroot"
            DependsOn       = "[WindowsFeature]web"
		
        }
      
        File WebContent
        {
            Ensure          = "Present"
			Force           = $true   
            SourcePath      = "c:\webfiles"
            DestinationPath = "c:\inetpub\webfiles"
            Recurse         = $true
            Type            = "Directory"
            DependsOn       = "[xWebsite]DefaultSiteStop"
			Credential      = $domainAdminCredentials
        }
		
		xWebsite webfiles
        {
            Ensure          = "Present"
            Name            = "webfiles"
            State           = "Started"
            PhysicalPath    = "c:\inetpub\webfiles"
            DependsOn       = "[File]WebContent"
        }

		
     }
}

configuration bdc
{ 
   param 
    ( 
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$domainAdmincredentials,

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    ) 
    
Import-DscResource -ModuleName PSDesiredStateConfiguration, xActiveDirectory, XComputerManagement
    
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($DomainAdmincredentials.UserName)", $DomainAdmincredentials.Password)
   
    Node localhost
    {
        LocalConfigurationManager            
        {            
            ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyOnly'            
            RebootNodeIfNeeded = $true            
           
      
        }
        WindowsFeature ADDSInstall 
        { 
            Ensure = "Present" 
            Name = "AD-Domain-Services"
        } 

        xWaitForADDomain DscForestWait 
        { 
            DomainName = $DomainName 
            DomainUserCredential= $DomainCreds
            RetryCount = $RetryCount 
            RetryIntervalSec = $RetryIntervalSec
        } 

        xADDomainController BDC 
        { 
            DomainName = $DomainName 
            DomainAdministratorCredential = $DomainCreds 
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath = "c:\NTDS"
            LogPath = "c:\NTDS"
            SysvolPath = "c:\SYSVOL"
        }
	   
    }
  
 }  

	 
Configuration fileserver
{
 
[CmdletBinding()]
 
Param (
    [string] $NodeName,
    [string] $domainName,
    [System.Management.Automation.PSCredential]$domainAdminCredentials
)
 
Import-DscResource -ModuleName PSDesiredStateConfiguration, XComputerManagement
 
Node localhost
    {
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyAndAutoCorrect'
            RebootNodeIfNeeded = $true
            ActionAfterReboot = 'ContinueConfiguration'
            AllowModuleOverwrite = $true
        }
 
         WindowsFeature ADPowershell
        {
            Name = "RSAT-AD-PowerShell"
            Ensure = "Present"
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
