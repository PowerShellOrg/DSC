Remove-Module DscConfiguration -Force -ErrorAction SilentlyContinue
Import-Module -Name $PSScriptRoot\DscConfiguration.psd1 -Force -ErrorAction Stop

Describe 'Resolve-DscConfigurationProperty' {
    $ConfigurationData = @{
        AllNodes = @();

        Services = @{
            TestService = @{
                ServiceLevel1 = @{
                    Property = 'Service Value'
                }

                NodeLevel1 = @{
                    Property = 'Service Value'
                }
            }
        }

        SiteData = @{
            All = @{
                GlobalLevel1 = @{
                    Property = 'Global Value'
                }

                SiteLevel1 = @{
                    Property = 'Global Value'
                }

                NodeLevel1 = @{
                    Property = 'Global Value'
                }

                ServiceLevel1 = @{
                    Property = 'Global Value'
                }
            }

            NY = @{
                SiteLevel1 = @{
                    Property = 'Site Value'
                }

                NodeLevel1 = @{
                    Property = 'Site Value'
                }

                ServiceLevel1 = @{
                    Property = 'Site Value'
                }
            }
        }
    }

    $Node = @{
        Name = 'TestNode'
        Location = 'NY'

        NodeLevel1 = @{
            Property = 'Node Value'
        }
    }

    It 'Returns the correct value on the node' {
        $scriptBlock = { Resolve-DscConfigurationProperty -Node $Node -PropertyName 'NodeLevel1\Property' }
        $scriptBlock | Should Not Throw
        & $scriptBlock | Should Be 'Node Value'
    }

    It 'Returns the correct value on the service' {
        $scriptBlock = { Resolve-DscConfigurationProperty -Node $Node -PropertyName 'ServiceLevel1\Property' }
        $scriptBlock | Should Not Throw
        & $scriptBlock | Should Be 'Service Value'
    }

    It 'Returns the correct value on the site' {
        $scriptBlock = { Resolve-DscConfigurationProperty -Node $Node -PropertyName 'SiteLevel1\Property' }
        $scriptBlock | Should Not Throw
        & $scriptBlock | Should Be 'Site Value'
    }

    It 'Returns the correct global value' {
        $scriptBlock = { Resolve-DscConfigurationProperty -Node $Node -PropertyName 'GlobalLevel1\Property'}
        $scriptBlock | Should Not Throw
        & $scriptBlock | Should Be 'Global Value'
    }
}
