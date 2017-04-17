

 Configuration Sample_InstallChromeBrowser

 Import-DscResource -ModuleName PSDesiredStateConfiguration, xchrome

{
    param
    (
    [Parameter(Mandatory)]
    $Language,
        
    [Parameter(Mandatory)]
    $LocalPath

	[Parameter(Mandatory)]
    $nodename
    
        
    )
    
    Import-DscResource -module xChrome
    
    MSFT_xChrome chrome
    {
    Language = $Language
    LocalPath = $LocalPath
    }
}