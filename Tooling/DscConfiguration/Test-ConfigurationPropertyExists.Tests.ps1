Remove-Module DscConfiguration -Force -ErrorAction SilentlyContinue
Import-Module -Name $PSScriptRoot\DscConfiguration.psd1 -Force -ErrorAction Stop

Describe 'Test-DscConfigurationPropertyExists' {
    $Node = @{
        NodeName = 'Node1'
        Location = 'Site'
        NodeHT = @{
            NodeValue = 'Set'
            NullValue = $null
        }
        MemberOfServices = @('Service1')
    }

    $configData = @{
        AllNodes = @($Node)
        SiteData = @{
            Site = @{
                SiteHT = @{
                    SiteValue = 'Set'
                }
            }
        }
        Services = @{
            Service1 = @{
                ServiceHT = @{
                    ServiceValue = 'Set'
                }
            }
        }
    }

    It 'Returns true for values that do exist' {
        Test-DscConfigurationPropertyExists -ConfigurationData $configData -Node $Node -PropertyName NodeHT | Should Be $true
        Test-DscConfigurationPropertyExists -ConfigurationData $configData -Node $Node -PropertyName NodeHT\NodeValue | Should Be $true
        Test-DscConfigurationPropertyExists -ConfigurationData $configData -Node $Node -PropertyName SiteHT | Should Be $true
        Test-DscConfigurationPropertyExists -ConfigurationData $configData -Node $Node -PropertyName SiteHT\SiteValue | Should Be $true
        Test-DscConfigurationPropertyExists -ConfigurationData $configData -Node $Node -PropertyName ServiceHT | Should Be $true
        Test-DscConfigurationPropertyExists -ConfigurationData $configData -Node $Node -PropertyName ServiceHT\ServiceValue | Should Be $true
        Test-DscConfigurationPropertyExists -ConfigurationData $configData -Node $Node -PropertyName NodeHT\NullValue | Should Be $true
    }

    It 'Returns false for values that do not exist' {
        Test-DscConfigurationPropertyExists -ConfigurationData $configData -Node $Node -PropertyName NodeHT\BogusValue | Should Be $false
        Test-DscConfigurationPropertyExists -ConfigurationData $configData -Node $Node -PropertyName BogusValue | Should Be $false
    }
}