function Test-DscBuild 
{   
    <#
    .Synopsis
        Runs a build of the Stack Exchange DSC configurations.
    .DESCRIPTION
        Creates an isolated runspace and executes a build, returning input immediately to the console window.
        This is the same process used by the build server to publish the current DSC configurations.

        WARNING: This will replace the current DSC resource modules on the machine running the build.
    .EXAMPLE
        Test-DscBuild -Development
        Runs a build to the Dsc-Dev folder that should be located adjacent to the Dsc-Prod folder.
    .EXAMPLE
        Test-DscBuild -DeploymentDirectory c:\temp -SkipResourcePackaging
        Runs a build to the c:\temp folder and does not create compressed versions of the resource modules 
        (saves a bit of time when repeatedly iterating on configuration changes)
    #>
    [cmdletbinding(DefaultParameterSetName = 'Manual')]
    param (      
        #The path to local copy of the DSC-Prod repository
        #Defaults to two folders above the DscDevelopment module (..\..\DscDevelopment)
        [parameter(
           Position = 0 
        )]
        [string]
        $WorkingDirectory = (Split-Path (Split-Path $psscriptroot)),        
        
        #The path to the script build script to run.
        #By default, this points to the TeamCityBuild folder adjacent to the DSC-Prod folder.
        [parameter(
           Position = 1
        )]
        [string]
        $BuildScript = (Join-Path (Split-Path (Split-Path (Split-Path $psscriptroot))) '\teamcitybuild\scripts\DSCBuild.ps1'),        

        #Destination for the generated configurations and packaged resources.
        #Two folders will be created underneath this location, one for Configurations and one for 
        #resource modules.
        [parameter(
            ParameterSetName = 'Manual',
            Position = 2 
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $DeploymentRoot,

        #
        [parameter()]
        [switch]
        $SkipResourcePackaging,

        [switch]
        $ShowConfigurationDebugMessages,

        [parameter(
            ParameterSetName = 'Production'
        )]
        [switch]
        $Production,
        [parameter(
            ParameterSetName = 'Development'
        )]
        [switch]
        $Development
    )

    $PassedParameters = @{
        WorkingDirectory = $WorkingDirectory     
        SkipResourcePackaging = $SkipResourcePackaging 
        ShowConfigurationDebugMessages = $ShowConfigurationDebugMessages 
        Verbose = $true
    }

    if (-not (Test-Path $WorkingDirectory))
    {
        throw @"
Working directory not found.  Please supply a path to the DSC-Prod repository.
"@
    }

    if ($PSBoundParameters.ContainsKey('DeploymentRoot'))
    {
        $PassedParameters.DestinationDirectory = $DeploymentRoot
    }
    elseif ($Production)
    {
        $PassedParameters.DestinationDirectory = '\\or-util02\c$\ProgramData\PSDSCPullServer'
    }
    elseif ($Development)
    {
        $PassedParameters.DestinationDirectory = Join-Path (Split-Path (Split-Path (Split-Path $psscriptroot))) 'DSC-Dev'    
    }
    else 
    {
        throw   "Need an environment or DeploymentRoot."  
    }
    if (-not (Test-Path $PassedParameters.DestinationDirectory))
    {
        mkdir $PassedParameters.DestinationDirectory
    }

    Write-Verbose "Parameters to pass are: "
    foreach ($key in $PassedParameters.Keys)
    {
        Write-Verbose "`t`tKey: $Key Value: $PassedParameters[$key]"
    }

    if (-not (Test-Path $BuildScript))
    {
        throw @"
Failed to find a build script at $BuildScript. 
Either specify a path to the build script or clone the TeamCityBuild repository adjacent to the DSC-Prod repo.
"@
    }
    
    start-job -ArgumentList $BuildScript, $PassedParameters {
            param ([string]$BuildScript, [System.Collections.Hashtable]$PassedParameters)
		    & $BuildScript @PassedParameters
	    } | receive-job -wait

}