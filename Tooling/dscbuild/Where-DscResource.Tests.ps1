$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.ps1", ".ps1")
$pathtosut = join-path $here $sut

iex ( gc $pathtosut -Raw )

<#
Describe 'how Test-ZippedModuleChanged reponds' {       
    $Setup = {
        mkdir testdrive:\Source -erroraction silentlycontinue | out-null
        $Source = get-item testdrive:\source | select -expand fullname

        mkdir testdrive:\Destination -erroraction silentlycontinue | out-null
        $Destination = get-item testdrive:\Destination | select -expand fullname        

        $InputObjectProperties = @{
            Name = 'MyCustomResource' 
            fullname = (join-path $Source 'MyCustomResource')
        }

        $InputObject = [pscustomobject]$InputObjectProperties
        
        mock -command Get-FileHash -parameterFilter {$path -like $InputObject.fullname} -mockwith {[pscustomobject]@{hash='123'}}
    }
    
	
	context "when the current version is the same as a previous version" {		
        . $Setup        
        mock -command test-path -mockwith {$true}
        mock -command Get-FileHash -parameterFilter {$path -like (Join-path $Destination 'MyCustomResource')} -mockwith {[pscustomobject]@{hash='123'}}

		$result = Test-ZippedModuleChanged  
		
		it "should return false" {
			$result | should be $false
		}
	}

    context "when the current version is the different as a previous version" {      
        . $Setup
        mock -command test-path -mockwith {$true}
        mock -command Get-FileHash -parameterFilter {$path -like (Join-path $Destination 'MyCustomResource')} -mockwith {[pscustomobject]@{hash='321'}}
        
        $result = Test-ZippedModuleChanged
        
        it "should return true" {
            $result | should be $true
        }
    }

    context "when no previous version exists" {      
        . $Setup
        mock -command test-path -mockwith {$false} 
        
        $result = Test-ZippedModuleChanged
        
        it "should return true" {
            $result | should be $true
        }
    }
}
#>

Describe 'how Test-DscModuleResourceIsValid behaves' {    

    context 'when there are failed DSC resources' {  
        mock Get-DscResourceForModule -mockwith {}              
        mock Get-FailedDscResource -mockwith {
            [pscustomobject]@{name='TestResource'},
            [pscustomobject]@{name='SecondResource'}
        }

        it 'should throw an exception' {
            { Test-DscModuleResourceIsValid} | 
                should throw
        }
    }   

    context 'when there are no DSC resources' {
        mock Get-DscResourceForModule -mockwith {}
        mock Get-FailedDscResource -mockwith {}

        $result = Test-DscModuleResourceIsValid 

        it 'should return true' {
            $result | should be $true
        }
    }

    context 'when all DSC resources are valid' {
        mock Get-DscResourceForModule -mockwith {
            [pscustomobject]@{name='TestResource'},
            [pscustomobject]@{name='SecondResource'}
        }
        mock Get-FailedDscResource -mockwith {}

        $result = Test-DscModuleResourceIsValid 
        
        it 'should return true' {
            $result | should be $true
        }
    }
}




