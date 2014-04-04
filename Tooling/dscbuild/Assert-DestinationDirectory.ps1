function Assert-DestinationDirectory {
    [cmdletbinding()]
    param ()

    $script:DscBuildParameters | 
        add-member -membertype Noteproperty -Name DestinationModuleDirectory -value (join-path $script:DscBuildParameters.DestinationDirectory 'Modules') -force
    if (Test-Path $script:DscBuildParameters.DestinationModuleDirectory)
    {        
        remove-item $script:DscBuildParameters.DestinationModuleDirectory -recurse -force  
    }
    Write-Verbose "Creating $($script:DscBuildParameters.DestinationModuleDirectory)"
    mkdir $script:DscBuildParameters.DestinationModuleDirectory | out-null

    $script:DscBuildParameters |
        add-member -membertype Noteproperty -Name DestinationConfigurationDirectory -value  (join-path $script:DscBuildParameters.DestinationDirectory 'Configuration') -force
    if (Test-Path $script:DscBuildParameters.DestinationConfigurationDirectory)
    {
        remove-item $script:DscBuildParameters.DestinationConfigurationDirectory -recurse -force  
    }
    Write-Verbose "Creating $($script:DscBuildParameters.DestinationConfigurationDirectory)"
    mkdir $script:DscBuildParameters.DestinationConfigurationDirectory | out-null

    $script:DscBuildParameters |
        add-member -membertype Noteproperty -Name ConfigurationOutputPath -value  (join-path $script:DscBuildParameters.WorkingDirectory 'BuildOutput\Configuration') -force
    if (Test-Path $script:DscBuildParameters.ConfigurationOutputPath)
    {
        remove-item $script:DscBuildParameters.ConfigurationOutputPath -recurse -force        
    }
    Write-Verbose "Creating $($script:DscBuildParameters.ConfigurationOutputPath)"
    mkdir $script:DscBuildParameters.ConfigurationOutputPath | out-null

    $script:DscBuildParameters |
        add-member -membertype Noteproperty -Name ModuleOutputPath -value  (join-path $script:DscBuildParameters.WorkingDirectory 'BuildOutput\Modules') -force
    if (Test-Path $script:DscBuildParameters.ModuleOutputPath)
    {
        remove-item $script:DscBuildParameters.ModuleOutputPath -recurse -force        
    }
    Write-Verbose "Creating $($script:DscBuildParameters.ModuleOutputPath)"
    mkdir $script:DscBuildParameters.ModuleOutputPath | out-null
}