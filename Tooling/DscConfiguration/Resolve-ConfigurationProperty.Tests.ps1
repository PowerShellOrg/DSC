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

                Nodes = @(
                    'TestNode'
                )
            }

            BogusService = @{
                ServiceLevel1 = @{
                    Property = 'Should Not Resolve'
                }

                Nodes = @()
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

    Context 'Single Values' {
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

    Context 'Multiple Values' {
        $ConfigurationData['Services']['NewService'] = @{
            Nodes = @(
                'TestNode'
            )

            ServiceLevel1 = @{
                Property = 'Service Value'
            }

            NodeLevel1 = @{
                Property = 'Service Value'
            }
        }

        It 'Throws an error if multiple services return a value and command is using default behavior' {
            $scriptBlock = { Resolve-DscConfigurationProperty -Node $Node -PropertyName 'ServiceLevel1\Property' }
            $scriptBlock | Should Throw 'More than one result was returned'
        }

        It 'Returns the proper results for multiple services' {
            $scriptBlock = { Resolve-DscConfigurationProperty -Node $Node -PropertyName 'ServiceLevel1\Property' -MultipleResultBehavior MultipleValuesFromServiceOnly }
            $scriptBlock | Should Not Throw

            $result = (& $scriptBlock) -join ', '
            $result | Should Be 'Service Value, Service Value'
        }

        It 'Returns the property results for all scopes' {
            $scriptBlock = { Resolve-DscConfigurationProperty -Node $Node -PropertyName 'NodeLevel1\Property' -MultipleResultBehavior AllValues }
            $scriptBlock | Should Not Throw

            $result = (& $scriptBlock) -join ', '
            $result | Should Be 'Node Value, Service Value, Service Value, Site Value, Global Value'
        }
    }
}
