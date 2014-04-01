$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.ps1", ".psm1")
if (-not (Test-Path $sut))
{
	$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.ps1", ".ps1")
}
if (-not (Test-Path $sut))
{
    Write-Error "Failed to find script to test at $sut"
}
$pathtosut = join-path $here $sut

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

        $result = Resolve-ConfigurationProperty -PropertyName 'PullServerPath' 
        
        it "should return the node's override" {
            $result | should be 'OverrideValue'
        }
    }

    context 'when a node does not override the site property' {
       
        $Node = @{
            Location = 'NY'            
        }

        $result = Resolve-ConfigurationProperty -PropertyName 'PullServerPath'
        it "should return the site's default value" {
            $result | should be 'ConfiguredBySite'
        }
    }

    context 'when a site does not have the property but the base configuration data does' {
        
        $Node = @{
            Location = 'OR'            
        }

        $result = Resolve-ConfigurationProperty -PropertyName 'PullServerPath' 
        it "should return the site's default value" {
            $result | should be 'ConfiguredByDefault'
        }
    }
}


describe 'how Resolve-ConfigurationProperty responds' {
    $ConfigurationData = @{
        Services = @{
            MyTestService = @{
                DataSource = 'MyDefaultValue'
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

        $result = Resolve-ConfigurationProperty -ServiceName MyTestService -PropertyName DataSource 

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

        $result = Resolve-ConfigurationProperty -ServiceName MyTestService -PropertyName DataSource

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

        $result = Resolve-ConfigurationProperty -ServiceName MyTestService -PropertyName DataSource 

        it 'should return the override from the site' {
            $result | should be 'MyDefaultValue'

        }
    }


}