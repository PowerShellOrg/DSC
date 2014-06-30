# This module file contains a utility to perform PSWS IIS Endpoint setup
# Module exports New-PSWSEndpoint function to perform the endpoint setup
#
#	Copyright (c) Microsoft Corporation, 2013
#
# Author: Raghu Shantha [RaghuS@Microsoft.com]
# ChangeLog: 7/11/2013 - Providing Dispatch/Port is now optional; Removed taking backup of existing endpoints since this was unnecessary and not performant; Logging only if something fails
#

# Validate supplied configuration to setup the PSWS Endpoint
# Function checks for the existence of PSWS Schema files, IIS config
# Also validate presence of IIS on the target machine
#
function Initialize-Endpoint
{
    param (
        $site,
        $path,
        $cfgfile,
        $port,
        $app,
        $applicationPoolIdentityType,
        $svc,
        $mof,
        $dispatch,        
        $asax,
        $dependentBinaries,
        $language,
        $dependentMUIFiles,
        $psFiles,
        $removeSiteFiles = $false,
        $certificateThumbPrint)
    
    if (!(Test-Path $cfgfile))
    {        
        throw "ERROR: $cfgfile does not exist"    
    }            
    
    if (!(Test-Path $svc))
    {        
        throw "ERROR: $svc does not exist"    
    }            
    
    if (!(Test-Path $mof))
    {        
        throw "ERROR: $mof does not exist"  
    }   	
    
    if (!(Test-Path $asax))
    {        
        throw "ERROR: $asax does not exist"  
    }  

    if ($certificateThumbPrint -ne "AllowUnencryptedTraffic")
    {    
        Write-Verbose "Verify that the certificate with the provided thumbprint exists in CERT:\LocalMachine\MY\"
        $certificate = Get-childItem CERT:\LocalMachine\MY\ | Where {$_.Thumbprint -eq $certificateThumbPrint}
        if (!$Certificate) 
        { 
             throw "ERROR: Certificate with thumbprint $certificateThumbPrint does not exist in CERT:\LocalMachine\MY\"
        }  
    }     
    
    Test-IISInstall
    
    $appPool = "PSWS"
    
    Write-Verbose "Delete the App Pool if it exists"
    Remove-AppPool -apppool $appPool
    
    Write-Verbose "Remove the site if it already exists"
    Update-Site -siteName $site -siteAction Remove
    
    if ($removeSiteFiles)
    {
        if(Test-Path $path)
        {
            Remove-Item -Path $path -Recurse -Force
        }
    }
    
    Copy-Files -path $path -cfgfile $cfgfile -svc $svc -mof $mof -dispatch $dispatch -asax $asax -dependentBinaries $dependentBinaries -language $language -dependentMUIFiles $dependentMUIFiles -psFiles $psFiles
    
    Update-AllSites Stop
    Update-DefaultAppPool Stop
    Update-DefaultAppPool Start
    
    New-IISWebSite -site $site -path $path -port $port -app $app -apppool $appPool -applicationPoolIdentityType $applicationPoolIdentityType -certificateThumbPrint $certificateThumbPrint
}

# Validate if IIS and all required dependencies are installed on the target machine
#
function Test-IISInstall
{
        Write-Verbose "Checking IIS requirements"
        $iisVersion = (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\InetStp -ErrorAction silentlycontinue).MajorVersion + (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\InetStp -ErrorAction silentlycontinue).MinorVersion
        
        if ($iisVersion -lt 7.0) 
        {
            throw "ERROR: IIS Version detected is $iisVersion , must be running higher than 7.0"            
        }        
        
        $wsRegKey = (Get-ItemProperty hklm:\SYSTEM\CurrentControlSet\Services\W3SVC -ErrorAction silentlycontinue).ImagePath
        if ($wsRegKey -eq $null)
        {
            throw "ERROR: Cannot retrive W3SVC key. IIS Web Services may not be installed"            
        }        
        
        if ((Get-Service w3svc).Status -ne "running")
        {
            throw "ERROR: service W3SVC is not running"
        }
}

# Verify if a given IIS Site exists
#
function Test-IISSiteExists
{
    param ($siteName)

    if (Get-Website -Name $siteName)
    {
        return $true
    }
    
    return $false
}

# Perform an action (such as stop, start, delete) for a given IIS Site
#
function Update-Site
{
    param (
        [Parameter(ParameterSetName = 'SiteName', Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]$siteName,

        [Parameter(ParameterSetName = 'Site', Mandatory, Position = 0)]        
        $site,

        [Parameter(ParameterSetName = 'SiteName', Mandatory, Position = 1)]
        [Parameter(ParameterSetName = 'Site', Mandatory, Position = 1)]
        [String]$siteAction)
    
    [String]$name = $null
    if ($PSCmdlet.ParameterSetName -eq 'SiteName')
    {
        $name = $siteName
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Site')
    {   
        $name = $site.Name
    }
    
    if (Test-IISSiteExists $name)
    {        
        switch ($siteAction) 
        { 
            "Start"  {Start-Website -Name $name} 
            "Stop"   {Stop-Website -Name $name -ErrorAction SilentlyContinue} 
            "Remove" {Remove-Website -Name $name}
        }
    }
}

# Delete the given IIS Application Pool
# This is required to cleanup any existing conflicting apppools before setting up the endpoint
#
function Remove-AppPool
{
    param ($appPool)    
    
    Remove-WebAppPool -Name $appPool -ErrorAction SilentlyContinue
}

# Perform given action(start, stop, delete) on all IIS Sites
#
function Update-AllSites
{
    param ($action)    
    
    foreach ($site in Get-Website)
    {
        Update-Site $site $action
    }
}

# Perform given action(start, stop) on the default app pool
#
function Update-DefaultAppPool
{
    param ($action) 
    
    switch ($action) 
    { 
        "Start"  {Start-WebAppPool -Name "DefaultAppPool"} 
        "Stop"   {Stop-WebAppPool -Name "DefaultAppPool"} 
        "Remove" {Remove-WebAppPool -Name "DefaultAppPool"}
    }
}

# Generate an IIS Site Id while setting up the endpoint
# The Site Id will be the max available in IIS config + 1
#
function New-SiteID
{
    return ((Get-Website | % { $_.Id } | Measure-Object -Maximum).Maximum + 1)
}

# Validate the PSWS config files supplied and copy to the IIS endpoint in inetpub
#
function Copy-Files
{
    param (
        $path,
        $cfgfile,
        $svc,
        $mof,    
        $dispatch,
        $asax,
        $dependentBinaries,
        $language,
        $dependentMUIFiles,
        $psFiles)    
    
    if (!(Test-Path $cfgfile))
    {
        throw "ERROR: $cfgfile does not exist"    
    }
    
    if (!(Test-Path $svc))
    {
        throw "ERROR: $svc does not exist"    
    }
    
    if (!(Test-Path $mof))
    {
        throw "ERROR: $mof does not exist"    
    }

    if (!(Test-Path $asax))
    {
        throw "ERROR: $asax does not exist"    
    }
    
    if (!(Test-Path $path))
    {
        $null = New-Item -ItemType container -Path $path        
    }
    
    foreach ($dependentBinary in $dependentBinaries)
    {
        if (!(Test-Path $dependentBinary))
        {					
            throw "ERROR: $dependentBinary does not exist"  
        } 	
    }

    foreach ($dependentMUIFile in $dependentMUIFiles)
    {
        if (!(Test-Path $dependentMUIFile))
        {					
            throw "ERROR: $dependentMUIFile does not exist"  
        } 	
    }
    
    Write-Verbose "Create the bin folder for deploying custom dependent binaries required by the endpoint"
    $binFolderPath = Join-Path $path "bin"
    $null = New-Item -path $binFolderPath  -itemType "directory" -Force
    Copy-Item $dependentBinaries $binFolderPath -Force
    
    if ($language)
    {
        $muiPath = Join-Path $binFolderPath $language

        if (!(Test-Path $muiPath))
        {
            $null = New-Item -ItemType container $muiPath        
        }
        Copy-Item $dependentMUIFiles $muiPath -Force
    }
    
    foreach ($psFile in $psFiles)
    {
        if (!(Test-Path $psFile))
        {					
            throw "ERROR: $psFile does not exist"  
        } 	
        
        Copy-Item $psFile $path -Force
    }		
    
    Copy-Item $cfgfile (Join-Path $path "web.config") -Force
    Copy-Item $svc $path -Force
    Copy-Item $mof $path -Force
    
    if ($dispatch)
    {
        Copy-Item $dispatch $path -Force
    }  
    
    if ($asax)
    {
        Copy-Item $asax $path -Force
    }
}

# Setup IIS Apppool, Site and Application
#
function New-IISWebSite
{
    param (
        $site,
        $path,    
        $port,
        $app,
        $appPool,        
        $applicationPoolIdentityType,
        $certificateThumbPrint)    
    
    $siteID = New-SiteID
    
    Write-Verbose "Adding App Pool"
    $null = New-WebAppPool -Name $appPool

    Write-Verbose "Set App Pool Properties"
    $appPoolIdentity = 4
    if ($applicationPoolIdentityType)
    {   
        # LocalSystem = 0, LocalService = 1, NetworkService = 2, SpecificUser = 3, ApplicationPoolIdentity = 4        
        if ($applicationPoolIdentityType -eq "LocalSystem")
        {
            $appPoolIdentity = 0
        }
        elseif ($applicationPoolIdentityType -eq "LocalService")
        {
            $appPoolIdentity = 1
        }      
        elseif ($applicationPoolIdentityType -eq "NetworkService")
        {
            $appPoolIdentity = 2
        }        
    } 

    $appPoolItem = Get-Item IIS:\AppPools\$appPool
    $appPoolItem.managedRuntimeVersion = "v4.0"
    $appPoolItem.enable32BitAppOnWin64 = $true
    $appPoolItem.processModel.identityType = $appPoolIdentity
    $appPoolItem | Set-Item
    
    Write-Verbose "Add and Set Site Properties"
    if ($certificateThumbPrint -eq "AllowUnencryptedTraffic")
    {
        $webSite = New-WebSite -Name $site -Id $siteID -Port $port -IPAddress "*" -PhysicalPath $path -ApplicationPool $appPool
    }
    else
    {
        $webSite = New-WebSite -Name $site -Id $siteID -Port $port -IPAddress "*" -PhysicalPath $path -ApplicationPool $appPool -Ssl

        # Remove existing binding for $port
        Remove-Item IIS:\SSLBindings\0.0.0.0!$port -ErrorAction Ignore

        # Create a new binding using the supplied certificate
        $null = Get-Item CERT:\LocalMachine\MY\$certificateThumbPrint | New-Item IIS:\SSLBindings\0.0.0.0!$port
    }
        
    Write-Verbose "Delete application"
    Remove-WebApplication -Name $app -Site $site -ErrorAction SilentlyContinue
    
    Write-Verbose "Add and Set Application Properties"
    $null = New-WebApplication -Name $app -Site $site -PhysicalPath $path -ApplicationPool $appPool
    
    Update-Site -siteName $site -siteAction Start    
}

# Allow Clients outsite the machine to access the setup endpoint on a User Port
#
function New-FirewallRule
{
    param ($firewallPort)
    
    Write-Verbose "Disable Inbound Firewall Notification"
    Set-NetFirewallProfile -Profile Domain,Public,Private -NotifyOnListen False
    
    Write-Verbose "Add Firewall Rule for port $firewallPort"    
    $null = New-NetFirewallRule -DisplayName "Allow Port $firewallPort for PSWS" -Direction Inbound -LocalPort $firewallPort -Protocol TCP -Action Allow
}

# Enable & Clear PSWS Operational/Analytic/Debug ETW Channels
#
function Enable-PSWSETW
{    
    # Disable Analytic Log
    & $script:wevtutil sl Microsoft-Windows-ManagementOdataService/Analytic /e:false /q | Out-Null    

    # Disable Debug Log
    & $script:wevtutil sl Microsoft-Windows-ManagementOdataService/Debug /e:false /q | Out-Null    

    # Clear Operational Log
    & $script:wevtutil cl Microsoft-Windows-ManagementOdataService/Operational | Out-Null    

    # Enable/Clear Analytic Log
    & $script:wevtutil sl Microsoft-Windows-ManagementOdataService/Analytic /e:true /q | Out-Null    

    # Enable/Clear Debug Log
    & $script:wevtutil sl Microsoft-Windows-ManagementOdataService/Debug /e:true /q | Out-Null    
}

<#
.Synopsis
   Create PowerShell WebServices IIS Endpoint
.DESCRIPTION
   Creates a PSWS IIS Endpoint by consuming PSWS Schema and related dependent files
.EXAMPLE
   New a PSWS Endpoint [@ http://Server:39689/PSWS_Win32Process] by consuming PSWS Schema Files and any dependent scripts/binaries
   New-PSWSEndpoint -site Win32Process -path $env:HOMEDRIVE\inetpub\wwwroot\PSWS_Win32Process -cfgfile Win32Process.config -port 39689 -app Win32Process -svc PSWS.svc -mof Win32Process.mof -dispatch Win32Process.xml -dependentBinaries ConfigureProcess.ps1, Rbac.dll -psFiles Win32Process.psm1
#>
function New-PSWSEndpoint
{
[CmdletBinding()]
    param (
        
        # Unique Name of the IIS Site        
        [String] $site = "PSWS",
        
        # Physical path for the IIS Endpoint on the machine (under inetpub/wwwroot)        
        [String] $path = "$env:HOMEDRIVE\inetpub\wwwroot\PSWS",
        
        # Web.config file        
        [String] $cfgfile = "web.config",
        
        # Port # for the IIS Endpoint        
        [Int] $port = 8080,
        
        # IIS Application Name for the Site        
        [String] $app = "PSWS",
        
        # IIS App Pool Identity Type - must be one of LocalService, LocalSystem, NetworkService, ApplicationPoolIdentity		
        [ValidateSet('LocalService', 'LocalSystem', 'NetworkService', 'ApplicationPoolIdentity')]		
        [String] $applicationPoolIdentityType,
        
        # WCF Service SVC file        
        [String] $svc = "PSWS.svc",
        
        # PSWS Specific MOF Schema File
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $mof,
        
        # PSWS Specific Dispatch Mapping File [Optional]
        [ValidateNotNullOrEmpty()]		
        [String] $dispatch,    
        
        # Global.asax file [Optional]
        [ValidateNotNullOrEmpty()]
        [String] $asax,
        
        # Any dependent binaries that need to be deployed to the IIS endpoint, in the bin folder
        [ValidateNotNullOrEmpty()]
        [String[]] $dependentBinaries,

         # MUI Language [Optional]
        [ValidateNotNullOrEmpty()]
        [String] $language,

        # Any dependent binaries that need to be deployed to the IIS endpoint, in the bin\mui folder [Optional]
        [ValidateNotNullOrEmpty()]
        [String[]] $dependentMUIFiles,
        
        # Any dependent PowerShell Scipts/Modules that need to be deployed to the IIS endpoint application root
        [ValidateNotNullOrEmpty()]
        [String[]] $psFiles,
        
        # True to remove all files for the site at first, false otherwise
        [Boolean]$removeSiteFiles = $false,

        # Enable Firewall Exception for the supplied port        
        [Boolean] $EnableFirewallException,

        # Enable and Clear PSWS ETW        
        [switch] $EnablePSWSETW,
        
        # Thumbprint of the Certificate in CERT:\LocalMachine\MY\ for Pull Server
        [String] $certificateThumbPrint = "AllowUnencryptedTraffic")
    
    $script:wevtutil = "$env:windir\system32\Wevtutil.exe"
       
    $svcName = Split-Path $svc -Leaf
    $protocol = "https:"
    if ($certificateThumbPrint -eq "AllowUnencryptedTraffic")
    {
        $protocol = "http:"
    }

    # Get Machine Name and Domain
    $cimInstance = Get-CimInstance -ClassName Win32_ComputerSystem
    
    Write-Verbose ("SETTING UP ENDPOINT at - $protocol//" + $cimInstance.Name + "." + $cimInstance.Domain + ":" + $port + "/" + $site + "/" + $svcName)
    Initialize-Endpoint -site $site -path $path -cfgfile $cfgfile -port $port -app $app `
                        -applicationPoolIdentityType $applicationPoolIdentityType -svc $svc -mof $mof `
                        -dispatch $dispatch -asax $asax -dependentBinaries $dependentBinaries `
                        -language $language -dependentMUIFiles $dependentMUIFiles -psFiles $psFiles `
                        -removeSiteFiles $removeSiteFiles -certificateThumbPrint $certificateThumbPrint
    
    if ($EnableFirewallException -eq $true)
    {
        Write-Verbose "Enabling firewall exception for port $port"
        $null = New-FirewallRule $port
    }

    if ($EnablePSWSETW)
    {
        Enable-PSWSETW
    }
    
    Update-AllSites start
    
}

<#
.Synopsis
   Set the option into the web.config for an endpoint
.DESCRIPTION
   Set the options into the web.config for an endpoint allowing customization.
.EXAMPLE
#>
function Set-AppSettingsInWebconfig
{
    param (
                
        # Physical path for the IIS Endpoint on the machine (possibly under inetpub/wwwroot)
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $path,
        
        # Key to add/update
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $key,

        # Value 
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $value

        )
                
    $webconfig = Join-Path $path "web.config"
    [bool] $Found = $false

    if (Test-Path $webconfig)
    {
        $xml = [xml](get-content $webconfig)
        $root = $xml.get_DocumentElement() 

        foreach( $item in $root.appSettings.add) 
        { 
            if( $item.key -eq $key ) 
            { 
                $item.value = $value; 
                $Found = $true;
            } 
        }

        if( -not $Found)
        {
            $newElement = $xml.CreateElement("add")                               
            $nameAtt1 = $xml.CreateAttribute("key")                    
            $nameAtt1.psbase.value = $key;                                
            $null = $newElement.SetAttributeNode($nameAtt1)
                                   
            $nameAtt2 = $xml.CreateAttribute("value")                      
            $nameAtt2.psbase.value = $value;                       
            $null = $newElement.SetAttributeNode($nameAtt2)       
                                   
            $null = $xml.configuration["appSettings"].AppendChild($newElement)   
        }
    }

    $xml.Save($webconfig) 
}

Export-ModuleMember -function New-PSWSEndpoint, Set-AppSettingsInWebconfig

