# The Get-TargetResource cmdlet.
function Get-TargetResource
{
    [OutputType([Hashtable])]
    param
    (
        # Prefix of the WCF SVC File
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$EndpointName,
            
        # Thumbprint of the Certificate in CERT:\LocalMachine\MY\ for Pull Server   
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]                         
        [string]$CertificateThumbPrint      
    )

    try
    {
        $webSite = Get-Website -Name $EndpointName

        if ($webSite)
        {
                # Get Full Path for Web.config file    
            $webConfigFullPath = Join-Path $website.physicalPath "web.config"

            $modulePath = Get-WebConfigAppSetting -WebConfigFullPath $webConfigFullPath -AppSettingName "ModulePath"
            $ConfigurationPath = Get-WebConfigAppSetting -WebConfigFullPath $webConfigFullPath -AppSettingName "ConfigurationPath"

            $UrlPrefix = $website.bindings.Collection[0].protocol + "://"

            $fqdn = $env:COMPUTERNAME
            if ($env:USERDNSDOMAIN)
            {
                $fqdn = $env:COMPUTERNAME + "." + $env:USERDNSDOMAIN
            }

            $iisPort = $website.bindings.Collection[0].bindingInformation.Split(":")[1]
                        
            $svcFileName = (Get-ChildItem -Path $website.physicalPath -Filter "*.svc").Name

            $serverUrl = $UrlPrefix + $fqdn + ":" + $iisPort + "/" + $webSite.name + "/" + $svcFileName

            $webBinding = Get-WebBinding -Name $EndpointName
            $certificateThumbPrint = $webBinding.certificateHash

            @{
                EndpointName = $EndpointName
                Port = $website.bindings.Collection[0].bindingInformation.Split(":")[1]
                PhysicalPath = $website.physicalPath
                State = $webSite.state
                ModulePath = $modulePath
                ConfigurationPath = $ConfigurationPath
                DSCServerUrl = $serverUrl
                CertificateThumbPrint = $certificateThumbPrint
            }
        }
    }
    catch
    {
        Write-Error "An error occured while retrieving settings for the website"
    }
}

# The Set-TargetResource cmdlet.
function Set-TargetResource
{
    param
    (
        # Prefix of the WCF SVC File
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$EndpointName,

        # Port number of the DSC Pull Server IIS Endpoint
        [Uint32]$Port = $( if ($IsComplianceServer) { 7070 } else { 8080 } ),

        # Physical path for the IIS Endpoint on the machine (usually under inetpub/wwwroot)                            
        [string]$PhysicalPath = "$env:SystemDrive\inetpub\wwwroot\$EndpointName",

        # Thumbprint of the Certificate in CERT:\LocalMachine\MY\ for Pull Server
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]                            
        [string]$CertificateThumbPrint,

        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",

        [ValidateSet("Started", "Stopped")]
        [string]$State = "Started",
    
        # Location on the disk where the Modules are stored            
        [string]$ModulePath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules",

        # Location on the disk where the Configuration is stored                    
        [string]$ConfigurationPath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration",

        # Is the endpoint for a DSC Compliance Server
        [boolean] $IsComplianceServer
    )

    # Initialize with default values        
    $pathPullServer = "$pshome\modules\PSDesiredStateConfiguration\PullServer"
    $rootDataPath ="$env:PROGRAMFILES\WindowsPowerShell\DscService"
    $jet4provider = "System.Data.OleDb"
    $jet4database = "Provider=Microsoft.Jet.OLEDB.4.0;Data Source=$env:PROGRAMFILES\WindowsPowerShell\DscService\Devices.mdb;"
    $eseprovider = "ESENT";
    $esedatabase = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Devices.edb";

    $culture = Get-Culture
    $language = $culture.TwoLetterISOLanguageName

    $os = [System.Environment]::OSVersion.Version
    $IsBlue = $false;
    if($os.Major -eq 6 -and $os.Minor -eq 3)
    {
        $IsBlue = $true;
    }

    # Use Pull Server values for defaults
    $webConfigFileName = "$pathPullServer\PSDSCPullServer.config"
    $svcFileName = "$pathPullServer\PSDSCPullServer.svc"
    $pswsMofFileName = "$pathPullServer\PSDSCPullServer.mof"
    $pswsDispatchFileName = "$pathPullServer\PSDSCPullServer.xml"

    # Update only if Compliance Server install is requested
    if ($IsComplianceServer)
    {
        $webConfigFileName = "$pathPullServer\PSDSCComplianceServer.config"
        $svcFileName = "$pathPullServer\PSDSCComplianceServer.svc"
        $pswsMofFileName = "$pathPullServer\PSDSCComplianceServer.mof"
        $pswsDispatchFileName = "$pathPullServer\PSDSCComplianceServer.xml"
    }
                
    Write-Verbose "Create the IIS endpoint"    
    xPSDesiredStateConfiguration\New-PSWSEndpoint -site $EndpointName `
                     -path $PhysicalPath `
                     -cfgfile $webConfigFileName `
                     -port $Port `
                     -applicationPoolIdentityType LocalSystem `
                     -app $EndpointName `
                     -svc $svcFileName `
                     -mof $pswsMofFileName `
                     -dispatch $pswsDispatchFileName `
                     -asax "$pathPullServer\Global.asax" `
                     -dependentBinaries  "$pathPullServer\Microsoft.Powershell.DesiredStateConfiguration.Service.dll" `
                     -language $language `
                     -dependentMUIFiles  "$pathPullServer\$language\Microsoft.Powershell.DesiredStateConfiguration.Service.Resources.dll" `
                     -certificateThumbPrint $CertificateThumbPrint `
                     -EnableFirewallException $true -Verbose

    Update-LocationTagInApplicationHostConfigForAuthentication -WebSite $EndpointName -Authentication "anonymous"
    Update-LocationTagInApplicationHostConfigForAuthentication -WebSite $EndpointName -Authentication "basic"
    Update-LocationTagInApplicationHostConfigForAuthentication -WebSite $EndpointName -Authentication "windows"
        

    if ($IsBlue)
    {
        Write-Verbose "Set values into the web.config that define the repository for BLUE OS"
        Set-AppSettingsInWebconfig -path $PhysicalPath -key "dbprovider" -value $eseprovider
        Set-AppSettingsInWebconfig -path $PhysicalPath -key "dbconnectionstr"-value $esedatabase
    }
    else
    {
        Write-Verbose "Set values into the web.config that define the repository for non-BLUE Downlevel OS"
        $repository = Join-Path "$rootDataPath" "Devices.mdb"
        Copy-Item "$pathPullServer\Devices.mdb" $repository -Force

        Set-AppSettingsInWebconfig -path $PhysicalPath -key "dbprovider" -value $jet4provider
        Set-AppSettingsInWebconfig -path $PhysicalPath -key "dbconnectionstr" -value $jet4database
    }

    if ($IsComplianceServer)
    {    
        Write-Verbose "Compliance Server: Set values into the web.config that indicate this is the admin endpoint"
        Set-AppSettingsInWebconfig -path $PhysicalPath -key "AdminEndPoint" -value "true"
    }
    else
    {
        Write-Verbose "Pull Server: Set values into the web.config that indicate the location of repository, configuration, modules"

        # Create the application data directory calculated above        
        $null = New-Item -path $rootDataPath -itemType "directory" -Force
                
        # Set values into the web.config that define the repository and where
        # configuration and modules files are stored. Also copy an empty database
        # into place.        
        Set-AppSettingsInWebconfig -path $PhysicalPath -key "dbprovider" -value $eseprovider
        Set-AppSettingsInWebconfig -path $PhysicalPath -key "dbconnectionstr" -value $esedatabase

        $repository = Join-Path $rootDataPath "Devices.mdb"
        Copy-Item "$pathPullServer\Devices.mdb" $repository -Force

        $null = New-Item -path "$ConfigurationPath" -itemType "directory" -Force

        Set-AppSettingsInWebconfig -path $PhysicalPath -key "ConfigurationPath" -value $ConfigurationPath

        $null = New-Item -path "$ModulePath" -itemType "directory" -Force

        Set-AppSettingsInWebconfig -path $PhysicalPath -key "ModulePath" -value $ModulePath	
    }
}

# The Test-TargetResource cmdlet.
function Test-TargetResource
{
	[OutputType([Boolean])]
    param
    (
        # Prefix of the WCF SVC File
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$EndpointName,

        # Port number of the DSC Pull Server IIS Endpoint
        [Uint32]$Port = $( if ($IsComplianceServer) { 7070 } else { 8080 } ),

        # Physical path for the IIS Endpoint on the machine (usually under inetpub/wwwroot)                            
        [string]$PhysicalPath = "$env:SystemDrive\inetpub\wwwroot\$EndpointName",

        # Thumbprint of the Certificate in CERT:\LocalMachine\MY\ for Pull Server
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]                            
        [string]$CertificateThumbPrint = "AllowUnencryptedTraffic",

        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",

        [ValidateSet("Started", "Stopped")]
        [string]$State = "Started",
    
        # Location on the disk where the Modules are stored            
        [string]$ModulePath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules",

        # Location on the disk where the Configuration is stored                    
        [string]$ConfigurationPath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration",

        # Is the endpoint for a DSC Compliance Server
        [boolean] $IsComplianceServer
    )

    $desiredConfigurationMatch = $true;

    $website = Get-Website -Name $EndpointName
    $stop = $true

    Do
    {
        Write-Verbose "Check Ensure"
        if(($Ensure -eq "Present" -and $website -eq $null) -or ($Ensure -eq "Absent" -and $website -ne $null))
        {
            $DesiredConfigurationMatch = $false            
            Write-Verbose "The Website $EndpointName is not present"
            break       
        }

        Write-Verbose "Check Port"
        $actualPort = $website.bindings.Collection[0].bindingInformation.Split(":")[1]
        if ($Port -ne $actualPort)
        {
            $DesiredConfigurationMatch = $false
            Write-Verbose "Port for the Website $EndpointName does not match the desired state."
            break       
        }

        Write-Verbose "Check Physical Path property"
        if(Test-WebsitePath -EndpointName $EndpointName -PhysicalPath $PhysicalPath)
        {
            $DesiredConfigurationMatch = $false
            Write-Verbose "Physical Path of Website $EndpointName does not match the desired state."
            break
        }

        Write-Verbose "Check State"
        if($website.state -ne $State -and $State -ne $null)
        {
            $DesiredConfigurationMatch = $false
            Write-Verbose "The state of Website $EndpointName does not match the desired state."
            break      
        }

        Write-Verbose "Get Full Path for Web.config file"
        $webConfigFullPath = Join-Path $website.physicalPath "web.config"
        if ($IsComplianceServer -eq $false)
        {
            Write-Verbose "Check ModulePath"
            if ($ModulePath)
            {
                if (-not (Test-WebConfigAppSetting -WebConfigFullPath $webConfigFullPath -AppSettingName "ModulePath" -ExpectedAppSettingValue $ModulePath))
                {
                    $DesiredConfigurationMatch = $false
                    break
                }
            }    

            Write-Verbose "Check ConfigurationPath"
            if ($ConfigurationPath)
            {
                if (-not (Test-WebConfigAppSetting -WebConfigFullPath $webConfigFullPath -AppSettingName "ConfigurationPath" -ExpectedAppSettingValue $ConfigurationPath))
                {
                    $DesiredConfigurationMatch = $false
                    break
                }
            }
        }
        $stop = $false
    }
    While($stop)  

    $desiredConfigurationMatch;
}

# Helper function used to validate website path
function Test-WebsitePath
{
    param
    (
        [string] $EndpointName,
        [string] $PhysicalPath
    )

    $pathNeedsUpdating = $false

    if((Get-ItemProperty "IIS:\Sites\$EndpointName" -Name physicalPath) -ne $PhysicalPath)
    {
        $pathNeedsUpdating = $true
    }

    $pathNeedsUpdating
}

# Helper function to Test the specified Web.Config App Setting
function Test-WebConfigAppSetting
{
    param
    (
        [string] $WebConfigFullPath,
        [string] $AppSettingName,
        [string] $ExpectedAppSettingValue
    )
    
    $returnValue = $true

    if (Test-Path $WebConfigFullPath)
    {
        $webConfigXml = [xml](get-content $WebConfigFullPath)
        $root = $webConfigXml.get_DocumentElement() 

        foreach ($item in $root.appSettings.add) 
        { 
            if( $item.key -eq $AppSettingName ) 
            {                 
                break
            } 
        }

        if($item.value -ne $ExpectedAppSettingValue)
        {
            $returnValue = $false
            Write-Verbose "The state of Web.Config AppSetting $AppSettingName does not match the desired state."
        }

    }
    $returnValue
}

# Helper function to Get the specified Web.Config App Setting
function Get-WebConfigAppSetting
{
    param
    (
        [string] $WebConfigFullPath,
        [string] $AppSettingName
    )
    
    $appSettingValue = ""
    if (Test-Path $WebConfigFullPath)
    {
        $webConfigXml = [xml](get-content $WebConfigFullPath)
        $root = $webConfigXml.get_DocumentElement() 

        foreach ($item in $root.appSettings.add) 
        { 
            if( $item.key -eq $AppSettingName ) 
            {     
                $appSettingValue = $item.value          
                break
            } 
        }        
    }
    
    $appSettingValue
}

# Helper to get current script Folder
function Get-ScriptFolder
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}

# Allow this Website to enable/disable specific Auth Schemes by adding <location> tag in applicationhost.config
function Update-LocationTagInApplicationHostConfigForAuthentication
{
    param (
        # Name of the WebSite        
        [String] $WebSite,

        # Authentication Type
        [ValidateSet('anonymous', 'basic', 'windows')]		
        [String] $Authentication
    )

    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration") | Out-Null

    $webAdminSrvMgr = new-object Microsoft.Web.Administration.ServerManager

    $appHostConfig = $webAdminSrvMgr.GetApplicationHostConfiguration()

    $authenticationType = $Authentication + "Authentication"
    $appHostConfigSection = $appHostConfig.GetSection("system.webServer/security/authentication/$authenticationType", $WebSite)
    $appHostConfigSection.OverrideMode="Allow"
    $webAdminSrvMgr.CommitChanges()
}

Export-ModuleMember -Function *-TargetResource