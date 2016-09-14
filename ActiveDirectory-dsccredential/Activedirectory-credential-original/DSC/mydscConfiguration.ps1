Configuration Main
{

Param ( [string] $nodeName )

Import-DscResource -ModuleName PSDesiredStateConfiguration

Node $nodeName
  {
   
    WindowsFeature telnetclient
    {
      Name = "telnet-client"
      Ensure = "Present"
    }
       
      
  }
}