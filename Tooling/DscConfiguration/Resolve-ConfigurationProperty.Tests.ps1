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

describe 'how Resolve-ConfigurationProperty responds' {
    $ConfigurationData = @{
        SiteData = @{
            All = @{
                PullServerPath = 'ConfiguredByDefault'
            }
            NY = @{                    
                PullServerPath = 'ConfiguredBySite'                    
            }
        }
        PullServerPath = 'ShouldNotReturn'
    }
    context 'when a node has an override for a site property' {
       
        $Node = @{
            Location = 'NY'
            PullServerPath = 'OverrideValue'
        }

        $result = Resolve-ConfigurationProperty -Node $Node -PropertyName 'PullServerPath' 
        
        it "should return the node's override" {
            $result | should be 'OverrideValue'
        }
    }

    context 'when a node does not override the site property' {
       
        $Node = @{
            Location = 'NY'            
        }

        $result = Resolve-ConfigurationProperty -Node $Node -PropertyName 'PullServerPath'
        it "should return the site's default value" {
            $result | should be 'ConfiguredBySite'
        }
    }

    context 'when a site does not have the property but the base configuration data does' {
        
        $Node = @{
            Location = 'OR'            
        }

        $result = Resolve-ConfigurationProperty -Node $Node -PropertyName 'PullServerPath' 
        it "should return the site's default value" {
            $result | should be 'ConfiguredByDefault'
        }
    }
}


describe 'how Resolve-ConfigurationProperty  responds' {
    $ConfigurationData = @{
        Services = @{
            MyTestService = @{
                DataSource = 'MyDefaultValue'
            }
            MySecondTestService = @{
                MissingFromFirstServiceConfig = 'FromSecondServiceConfig'
            }
        }            
    }
    context 'when a default value is supplied for a service and node has a property override' {

        $Node = @{
            Location = 'NY'
            Services = @{
                MyTestService = @{
                    DataSource = 'MyCustomValue'
                }
            }
        }

        $result = Resolve-ConfigurationProperty -Node $Node -ServiceName MyTestService -PropertyName DataSource 

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
            Location = 'NY'
        }

        $result = Resolve-ConfigurationProperty -Node $Node -ServiceName MyTestService -PropertyName DataSource

        it 'should return the override from the site' {
            $result | should be 'MySiteValue'

        }
    }

    context 'when no node or site level override is present' {
        $ConfigurationData.SiteData = @{
            NY = @{  
                Services = @{                  
                    MyTestService = @{}                    
                }
            }
        }
        $Node = @{
            Location = 'NY'
        }

        $result = Resolve-ConfigurationProperty -Node $Node -ServiceName MyTestService -PropertyName DataSource 

        it 'should return the default value from the service' {
            $result | should be 'MyDefaultValue'

        }
    }

    context 'when no service default is specified' {

        $Node = @{
            Location = 'NY'
            MissingFromFirstServiceConfig = 'FromNodeWithoutService'
        }

        $result = Resolve-ConfigurationProperty -Node $Node -ServiceName MyTestService -PropertyName MissingFromFirstServiceConfig 
        it 'should fall back to checking for the parameter without the service name' {
            $result | should be 'FromNodeWithoutService'
        }
    }

    context 'when two services are specified default is specified' {

        $Node = @{
            Location = 'NY'
            MissingFromFirstServiceConfig = 'FromNodeWithoutService'
        }

        $result = Resolve-ConfigurationProperty -Node $Node -ServiceName MyTestService, MySecondTestService -PropertyName MissingFromFirstServiceConfig 
        it 'should retrieve the parameter from the second service before falling back to the node' {
            $result | should be 'FromSecondServiceConfig'
        }
    }


}