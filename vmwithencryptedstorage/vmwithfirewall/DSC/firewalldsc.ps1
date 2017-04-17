configuration Main
{
    param
    (
        [string[]] $NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xNetworking

    Node $NodeName
    {
        xFirewall Firewall
        {
            Name                  = 'NotePadFirewallRule'
            DisplayName           = 'Firewall Rule for Notepad.exe'
            Group                 = 'NotePad Firewall Rule Group'
            Ensure                = 'Present'
            Enabled               = 'True'
            Profile               = ('Domain', 'Private')
            Direction             = 'OutBound'
            RemotePort            = ('8080', '8081')
            LocalPort             = ('9080', '9081')
            Protocol              = 'TCP'
            Description           = 'Firewall Rule for Notepad.exe'
            Program               = 'c:\windows\system32\notepad.exe'
            Service               = 'WinRM'
        }
    }
 }