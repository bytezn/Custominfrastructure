Configuration Main
{

Param (
    [string] $NodeName,
    [string] $domainName,
    [System.Management.Automation.PSCredential]$domainAdminCredentials
)

Import-DscResource -ModuleName PSDesiredStateConfiguration

Node $nodeName

{


 	WindowsFeature fileandstorage-services 
 	{
 		Name                      = "filestorage"
 		Credential                = $domainAdminCredentials
 		Ensure                    = "Present"
 		IncludeAllSubFeature      = $true
 	}
 
}

}

