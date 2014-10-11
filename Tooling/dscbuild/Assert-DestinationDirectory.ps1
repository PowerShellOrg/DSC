function Assert-DestinationDirectory {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param ()

    if ( Test-BuildResource ) {

        if ($pscmdlet.shouldprocess('module folders')) {}
        Add-DscBuildParameter -Name DestinationModuleDirectory -value (join-path $script:DscBuildParameters.DestinationRootDirectory 'Modules') @psboundparameters
        Add-DscBuildParameter -Name ModuleOutputPath -value  (join-path $script:DscBuildParameters.WorkingDirectory 'BuildOutput\Modules') @psboundparameters
        Add-DscBuildParameter -Name DestinationToolsDirectory -value $script:DscBuildParameters.DestinationToolDirectory @psboundparameters

        Assert-Directory -path $script:DscBuildParameters.DestinationToolsDirectory @psboundparameters
        Assert-Directory -path $script:DscBuildParameters.DestinationModuleDirectory @psboundparameters
        Assert-Directory -path $script:DscBuildParameters.ModuleOutputPath @psboundparameters
    }

    if ( Test-BuildConfiguration) {
        if ($pscmdlet.shouldprocess('configuration folders')) {}
        Add-DscBuildParameter -Name DestinationConfigurationDirectory -value  (join-path $script:DscBuildParameters.DestinationRootDirectory 'Configuration') @psboundparameters
        Add-DscBuildParameter -Name ConfigurationOutputPath -value  (join-path $script:DscBuildParameters.WorkingDirectory 'BuildOutput\Configuration') @psboundparameters

        Assert-Directory -path $script:DscBuildParameters.DestinationConfigurationDirectory @psboundparameters
        Assert-Directory -path $script:DscBuildParameters.ConfigurationOutputPath @psboundparameters
    }

    if ( Test-BuildTools ) {
        if ($pscmdlet.shouldprocess('tools folders')) {}
        Add-DscBuildParameter -Name DestinationToolsDirectory -value $script:DscBuildParameters.DestinationToolDirectory @psboundparameters
        Assert-Directory -path $script:DscBuildParameters.DestinationToolsDirectory @psboundparameters
    }

}

function Assert-Directory {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param (
        $Path
    )

    try {
        if (-not (Test-Path $path -ea Stop)) {
            $output = mkdir @psboundparameters
        }
    }
    catch {
        Write-Warning "Failed to validate $path"
        throw $_.Exception
    }
}




