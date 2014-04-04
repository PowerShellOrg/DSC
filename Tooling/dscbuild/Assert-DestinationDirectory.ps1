function Assert-DestinationDirectory {
    [cmdletbinding()]
    param ()

    $script:DscBuildParameters | 
        add-member -membertype Noteproperty -Name DestinationModuleDirectory -value (join-path $script:DscBuildParameters.DestinationDirectory 'Modules') -force
    if (-not (Test-Path $script:DscBuildParameters.DestinationModuleDirectory))
    {        
        Write-Verbose "Creating $($script:DscBuildParameters.DestinationModuleDirectory)"
        mkdir $script:DscBuildParameters.DestinationModuleDirectory | out-null
    }
    

    $script:DscBuildParameters |
        add-member -membertype Noteproperty -Name DestinationConfigurationDirectory -value  (join-path $script:DscBuildParameters.DestinationDirectory 'Configuration') -force
    if (-not (Test-Path $script:DscBuildParameters.DestinationConfigurationDirectory))
    {
        Write-Verbose "Creating $($script:DscBuildParameters.DestinationConfigurationDirectory)"
        mkdir $script:DscBuildParameters.DestinationConfigurationDirectory | out-null
    }
    

    $script:DscBuildParameters |
        add-member -membertype Noteproperty -Name ConfigurationOutputPath -value  (join-path $script:DscBuildParameters.WorkingDirectory 'BuildOutput\Configuration') -force
    if (-not (Test-Path $script:DscBuildParameters.ConfigurationOutputPath))
    {
        Write-Verbose "Creating $($script:DscBuildParameters.ConfigurationOutputPath)"
        mkdir $script:DscBuildParameters.ConfigurationOutputPath | out-null
    }
    

    $script:DscBuildParameters |
        add-member -membertype Noteproperty -Name ModuleOutputPath -value  (join-path $script:DscBuildParameters.WorkingDirectory 'BuildOutput\Modules') -force
    if (-not (Test-Path $script:DscBuildParameters.ModuleOutputPath))
    {
        Write-Verbose "Creating $($script:DscBuildParameters.ModuleOutputPath)"
        mkdir $script:DscBuildParameters.ModuleOutputPath | out-null      
    }
    
}