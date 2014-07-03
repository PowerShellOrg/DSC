$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.ps1", ".psm1")
if (-not (Test-Path $sut))
{
	$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.ps1", ".ps1")
}
$pathtosut = join-path $here $sut
if (-not (Test-Path $pathtosut))
{
    Write-Error "Failed to find script to test at $pathtosut"
}


iex ( gc $pathtosut -Raw )

describe 'how Resolve-DscConfigurationProperty responds' {
    
    $ConfigurationData = @{
        AllNodes = @(); 
        SiteData = @{}; 
        Services = @{}; 
        Applications = @{};
    }
    $ConfigurationData.SiteData = @{ NY = @{ PullServerPath = 'ConfiguredBySite' } }  
    context 'when a node has an override for a site property' {        
        $Node = @{
            Name = 'TestBox'
            Location = 'NY'
            PullServerPath = 'ConfiguredByNode'
        }

        $result = Resolve-DscConfigurationProperty -Node $Node -PropertyName 'PullServerPath' 
        
        it "should return the node's override" {
            $result | should be 'ConfiguredByNode'
        }
    }

    context 'when a node does not override the site property' {                   
        $Node = @{
            Name = 'TestBox'
            Location = 'NY'            
        }

        $result = Resolve-DscConfigurationProperty -Node $Node -PropertyName 'PullServerPath'
        it "should return the site's default value" {
            $result | should be 'ConfiguredBySite'
        }
    }

    context 'when a specific site does not have the property but the base configuration data does' {
        $ConfigurationData.SiteData = @{
            All = @{ PullServerPath = 'ConfiguredByDefault' }
            NY = @{ PullServerPath = 'ConfiguredBySite' }
        }            
        
        $Node = @{
            Name = 'TestBox'
            Location = 'OR'            
        }

        $result = Resolve-DscConfigurationProperty -Node $Node -PropertyName 'PullServerPath' 
        it "should return the site's default value" {
            $result | should be 'ConfiguredByDefault'
        }
    }
}

describe 'how Resolve-DscConfigurationProperty (services) responds' {
    $ConfigurationData = @{AllNodes = @(); SiteData = @{} ; Services = @{}; Applications = @{}}

    $ConfigurationData.Services = @{
        MyTestService = @{
            DataSource = 'MyDefaultValue'
        }        
    }            
    
    context 'when a default value is supplied for a service and node has a property override' {

        $Node = @{
            Name = 'TestBox'
            Location = 'NY'            
            Services = @{
                MyTestService = @{
                    DataSource = 'MyCustomValue'
                }
            }
        }

        $result = Resolve-DscConfigurationProperty -Node $Node -ServiceName MyTestService -PropertyName DataSource

        it 'should return the override from the node' {
            $result | should be 'MyCustomValue'

        }
    }

    context 'when a site level override is present' {
        $ConfigurationData.SiteData = @{
            NY = @{   
                Services = @{
                    MyTestService = @{
                        DataSource = 'MySiteValue'
                    }                
                }       
            }
        }
        $Node = @{
            Name = 'TestBox'
            Location = 'NY'
        }

        $result = Resolve-DscConfigurationProperty -Node $Node -ServiceName MyTestService -PropertyName DataSource 

        it 'should return the override from the site' {
            $result | should be 'MySiteValue'
        }
    }

    context 'when a global site level override is present' {
        $ConfigurationData.SiteData = @{
            All = @{
                Services = @{
                    MyTestService =  @{
                            DataSource = 'FromAllSite'
                        } 
                }
            }
            NY = @{   
                Services = @{
                    MyTestService = @{}                
                }       
            }
        }
        $ConfigurationData.Services = @{
            MyTestService = @{}
        }
        $Node = @{
            Name = 'TestBox'
            Location = 'NY'
        }

        $result = Resolve-DscConfigurationProperty -Node $Node -ServiceName MyTestService -PropertyName DataSource

        it 'should return the override from the site' {
            $result | should be 'FromAllSite'

        }
    }

    context 'when no node or site level override is present' {
        $ConfigurationData.Services = @{
            MyTestService = @{
                DataSource = 'MyDefaultValue'
            }
        }
        $ConfigurationData.SiteData = @{
            All = @{ DataSource = 'NotMyDefaultValue'}
            NY = @{  
                Services = @{                  
                    MyTestService = @{}                    
                }
            }
        }
        $Node = @{
            Name = 'TestBox'
            Location = 'NY'
        }

        $result = Resolve-DscConfigurationProperty -Node $Node -ServiceName MyTestService -PropertyName DataSource 

        it 'should return the default value from the service' {
            $result | should be 'MyDefaultValue'

        }
    }

    context 'when no service default is specified' {

        $Node = @{
            Name = 'TestBox'
            Location = 'NY'
            MissingFromFirstServiceConfig = 'FromNodeWithoutService'
        }

        $result = Resolve-DscConfigurationProperty -Node $Node -ServiceName MyTestService -PropertyName MissingFromFirstServiceConfig 
        it 'should fall back to checking for the parameter without the service name' {
            $result | should be 'FromNodeWithoutService'
        }
    }

    context 'when two services are specified default is specified' {
        $ConfigurationData.Services = @{ 
            MyTestService = @{}
            MySecondTestService = @{
                MissingFromFirstServiceConfig = 'FromSecondServiceConfig'
            }
        }
        $Node = @{
            Name = 'TestBox'
            Location = 'NY'            
        }
        
        $result = Resolve-DscConfigurationProperty -Node $Node -ServiceName MyTestService, MySecondTestService -PropertyName MissingFromFirstServiceConfig 
        
        it 'should retrieve the parameter from the second service before falling back to the node' {
            $result | should be 'FromSecondServiceConfig'
        }
    }
}

describe 'how Resolve-DscConfigurationProperty (applications) responds' {
    $ConfigurationData = @{AllNodes = @(); SiteData = @{} ; Services = @{}; Applications = @{}}
    $ConfigurationData.Applications = @{
        Git = @{ 
            LocalPath = 'c:\installs\Git\'
            InstallerName = 'setup.exe'
            SourcePath = 'c:\global\git\setup.exe' 
        }
        Mercurial = @{
            LocalPath = 'c:\installs\Mercurial\' 
            SourcePath = 'c:\global\Mercurial\setup.exe' 
            InstallerName = 'Setup.exe'
        } 
        WinMerge = @{ 
            LocalPath = 'c:\installs\winmerge\'
            InstallerName = 'setup.exe'
            SourcePath = 'c:\global\winmerge\setup.exe' 
        } 
    }
    $ConfigurationData.SiteData.NY = @{
        Applications = @{ 
            Mercurial = @{
                LocalPath = 'c:\installs\Mercurial\' 
                SourcePath = 'c:\site\Mercurial\setup.exe' 
                InstallerName = 'Setup.exe'
            } 
            WinMerge = @{ 
                LocalPath = 'c:\installs\winmerge\'
                InstallerName = 'setup.exe'
                SourcePath = 'c:\site\winmerge\setup.exe' 
            }  
        }
    }
    $Node = @{
        Name = 'TestBox'
        Location = 'NY' 
        Applications = @{ 
            WinMerge = @{ 
                LocalPath = 'c:\installs\winmerge\'
                InstallerName = 'setup.exe'
                SourcePath = 'c:\node\winmerge\setup.exe' 
            } 
        }
    }
    context 'When there is a base setting for an application' { 

        $result = Resolve-DscConfigurationProperty -Node $Node -Application 'Git'

        it 'should return the application level configuration' {
            $result.SourcePath | should be 'c:\global\git\setup.exe' 
        }
    }

    context 'When there is a site level override for the base setting for an application' {
        
        $result = Resolve-DscConfigurationProperty -Node $Node -Application 'Mercurial' 

        it 'should return the site application level configuration' {
            $result.SourcePath | should be 'c:\site\Mercurial\setup.exe' 
        }
    }

    context 'When there is a node level override for the base setting for an application' {

        $result = Resolve-DscConfigurationProperty -Node $Node -Application 'WinMerge' 

        it 'should return the node application level configuration' {
            $result.SourcePath | should be 'c:\node\winmerge\setup.exe' 
        }
    }
}
#<#
describe 'how Resolve-DscConfigurationProperty (applications/services) responds' {
    $ConfigurationData = @{AllNodes = @(); SiteData = @{} ; Services = @{}; Applications = @{}}
    $ConfigurationData.Applications.Sublime = @{
        LocalPath = 'c:\installs\Sublime\'
        InstallerName = 'setup.exe'
        SourcePath = 'c:\default\Sublime\setup.exe' 
    }
    $ConfigurationData.Services = @{ 
        BuildAgent = @{ 
            Applications = @{ 
                Git = @{ 
                    LocalPath = 'c:\installs\Git\'
                    InstallerName = 'setup.exe'
                    SourcePath = 'c:\global\git\setup.exe' 
                }
                Mercurial = @{
                    LocalPath = 'c:\installs\Mercurial\' 
                    SourcePath = 'c:\global\Mercurial\setup.exe' 
                    InstallerName = 'Setup.exe'
                } 
                WinMerge = @{ 
                    LocalPath = 'c:\installs\winmerge\'
                    InstallerName = 'setup.exe'
                    SourcePath = 'c:\global\winmerge\setup.exe' 
                } 
            }
        }
    }
    $ConfigurationData.SiteData.NY = @{ 
        Services = @{
            BuildAgent =  @{
                Applications = @{ 
                    Mercurial = @{
                        LocalPath = 'c:\installs\Mercurial\' 
                        SourcePath = 'c:\site\Mercurial\setup.exe' 
                        InstallerName = 'Setup.exe'
                    } 
                    WinMerge = @{ 
                        LocalPath = 'c:\installs\winmerge\'
                        InstallerName = 'setup.exe'
                        SourcePath = 'c:\site\winmerge\setup.exe' 
                    }  
                }
            }  
        }
    }
    $Node = @{
        Name = 'TestBox'
        Location = 'NY' 
        Services = @{
            BuildAgent = @{
                Applications = @{ 
                    WinMerge = @{ 
                        LocalPath = 'c:\installs\winmerge\'
                        InstallerName = 'setup.exe'
                        SourcePath = 'c:\node\winmerge\setup.exe' 
                    } 
                }
            }
        }
    }
    context 'When there is a base setting for an application' { 

        $result = Resolve-DscConfigurationProperty -Node $Node -Application 'Git' -ServiceName 'BuildAgent' 

        it 'should return the application level configuration' {
            $result.SourcePath | should be 'c:\global\git\setup.exe' 
        }
    }

    context 'When there is a site level override for the base setting for an application' {
        
        $result = Resolve-DscConfigurationProperty -Node $Node -Application 'Mercurial' -ServiceName 'BuildAgent' 

        it 'should return the site application level configuration' {
            $result.SourcePath | should be 'c:\site\Mercurial\setup.exe' 
        }
    }

    context 'When there is a node level override for the base setting for an application' {

        $result = Resolve-DscConfigurationProperty -Node $Node -Application 'WinMerge' -ServiceName 'BuildAgent' 

        it 'should return the node application level configuration' {
            $result.SourcePath | should be 'c:\node\winmerge\setup.exe' 
        }
    }

    context 'When there is no service level setting for an application, but there is a default config' {

        $result = Resolve-DscConfigurationProperty -Node $Node -Application 'Sublime' -ServiceName 'BuildAgent' 

        it 'should return the node application level configuration' {
            $result.SourcePath | should be 'c:\default\Sublime\setup.exe' 
        }
    }
}
#>
