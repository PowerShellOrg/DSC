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
        Runs a build to the Dsc-Dev folder that should be located in the working directory.
    .EXAMPLE
        Test-DscBuild -DeploymentDirectory c:\temp 
        Runs a build to the c:\temp folder and does not create compressed versions of the resource modules 
        (saves a bit of time when repeatedly iterating on configuration changes)
    #>
    [cmdletbinding(supportsshouldprocess=$true)]
    param (      
        #The path to local copy of the DSC-Prod repository
        #Defaults to two folders above the DscDevelopment module (..\..\DscDevelopment)
        [parameter(
           Position = 0 
        )]
        [string]
        $WorkingDirectory = (Split-Path (Split-Path $psscriptroot)),        
        
        #The path to the script build script to run.
        #By default, this points to the TeamCityBuild folder in the working directory.
        [parameter(            
            Position = 1
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $BuildScript,        

        #Destination for the generated configurations and packaged resources.
        #Two folders will be created underneath this location, one for Configurations and one for 
        #resource modules.
        [parameter(
            Mandatory,
            Position = 2 
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationRootDirectory,

        [parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationToolDirectory,

        [parameter()]
        [string]
        $CurrentToolsDirectory,

        #
        [parameter()]
        [switch]
        $ConfigurationOnly,

        [parameter()]
        [switch]
        $ResourceOnly,

        [parameter()]
        [switch]
        $ToolsOnly,
      
    	[switch]
    	$CleanEnvironment,        

        [switch]
        $ShowConfigurationDebugMessages
    )

    $PassedParameters = @{
        WorkingDirectory = $WorkingDirectory     
        DestinationToolDirectory = $DestinationToolDirectory
        CurrentToolsDirectory = $CurrentToolsDirectory
        ConfigurationOnly = $ConfigurationOnly        
        ResourceOnly = $ResourceOnly
        ToolsOnly = $ToolsOnly        
        ShowConfigurationDebugMessages = $ShowConfigurationDebugMessages          
    }

    foreach ($key in ('Whatif', 'Verbose', 'Debug'))
    {
        if ($PSBoundParameters.ContainsKey($key)) {        
            $PassedParameters[$key] = $PSBoundParameters[$key]
        }
    }

    if (-not (Test-Path $WorkingDirectory))
    {
        throw 'Working directory not found.  Please supply a path to the directory with DSC_Resources and DSC_Configuration repositories.'
    }

    if ($PSBoundParameters.ContainsKey('DestinationRootDirectory'))
    {
        $PassedParameters.DestinationRootDirectory = $DestinationRootDirectory
    }
    else 
    {
        throw   "Need to supply a DestinationRootDirectory."  
    }

    Write-Verbose "Parameters to pass are: "
    foreach ($key in $PassedParameters.Keys)
    {
        Write-Verbose "`t`tKey: $Key Value: $($PassedParameters[$key])"
    }

    if (-not (Test-Path $BuildScript))
    {
        throw @"
Failed to find a build script at $BuildScript. 
Either specify a path to the build script or clone the TeamCityBuild repository adjacent to the DSC-Prod repo.
"@
    }

	if ($CleanEnvironment) {
		remove-item (join-path $PassedParameters.DestinationDirectory 'Configuration') -recurse -erroraction SilentlyContinue
		remove-item (join-path $PassedParameters.DestinationDirectory 'Modules') -recurse -erroraction SilentlyContinue
        remove-item (join-path $PassedParameters.WorkingDirectory 'BuildOutput') -recurse -erroraction SilentlyContinue
	}    

    start-job -ArgumentList $BuildScript, $PassedParameters {
            param ([string]$BuildScript, [System.Collections.Hashtable]$PassedParameters)
		    . $BuildScript @PassedParameters
	    } | receive-job -wait

}


