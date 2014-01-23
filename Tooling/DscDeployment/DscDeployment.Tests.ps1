$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.ps1", ".psm1")
$pathtosut = join-path $here $sut

iex ( ((gc $pathtosut -Raw) -replace '\$psscriptroot', $here) )

Describe 'how Resolve-ModuleMetadataFile responds' {

    Context 'when passed a DirectoryInfo object with a module manifest' {       

        $testdirectory = mkdir "testdrive:\testmodule"             
        'test' | out-file "testdrive:\testmodule\testmodule.psd1"

        $result = $testdirectory | Resolve-ModuleMetadataFile

        It 'should return path to the module metadata file.' {
            $result | should be (Convert-path "testdrive:\testmodule\testmodule.psd1")
        }
    }

    Context 'when passed a DirectoryInfo object without module manifest' {                
        
        $testdirectory = mkdir "testdrive:\testmodule" 

        $result = Resolve-ModuleMetadataFile -InputObject $testdirectory -ErrorVariable ErrorResult -erroraction silentlycontinue
        
        It 'should return null or empty.' {
            $result | should BeNullOrEmpty
        }
        It 'should write a non-terminating error.' {
            $ErrorResult.Exception.Message | should match ("Failed to find a module metadata file at*")
        }
    }

    Context 'When a Path is passed to a module folder with a manifest' {
        
        mkdir "testdrive:\testmodule" | Out-Null
        'test' | out-file "testdrive:\testmodule\testmodule.psd1"

        $result = Resolve-ModuleMetadataFile -Path "testdrive:\testmodule" 

        It 'should return the path with the module metadata folder.' {
            $result | should be (Convert-path "testdrive:\testmodule\testmodule.psd1")         
        }
    }

    Context 'When a Path is passed to a psm1 file in a folder with a manifest' {
        
        mkdir "testdrive:\testmodule" | Out-Null
        'test' | out-file "testdrive:\testmodule\testmodule.psd1"
        'test' | out-file "testdrive:\testmodule\testmodule.psm1"

        $result = Resolve-ModuleMetadataFile -Path "testdrive:\testmodule\testmodule.psm1"

        It 'should return the path with the module metadata folder.' {
            $result | should be (Convert-path "testdrive:\testmodule\testmodule.psd1")         
        }
    }

    Context 'When a Path is passed to a module folder without a manifest' {
        
        mkdir "testdrive:\testmodule" | Out-Null        

        $result = Resolve-ModuleMetadataFile -Path "testdrive:\testmodule" -ErrorVariable ErrorResult -erroraction silentlycontinue

        It 'should return null or empty.' {
            $result | should BeNullOrEmpty
        }
        It 'should write a non-terminating error.' {
            $ErrorResult.Exception.Message | should match ("Failed to find a module metadata file at*")
        }
    }

    Context 'When a Path is passed to a manifest that does not exist' {
        
        mkdir "testdrive:\testmodule" | Out-Null        

        $result = Resolve-ModuleMetadataFile -Path "testdrive:\testmodule\testmodule.psd1" -ErrorVariable ErrorResult -erroraction silentlycontinue

        It 'should return null or empty.' {
            $result | should BeNullOrEmpty
        }
        It 'should write a non-terminating error.' {
            $ErrorResult.Exception.Message | should match ("Failed to find a module metadata file at*")
        }
    }

    Context 'When a Path to a folder that does not exist is passed' {              

        $result = Resolve-ModuleMetadataFile -Path "testdrive:\testmodule" -ErrorVariable ErrorResult -erroraction silentlycontinue

        It 'should return null or empty.' {
            $result | should BeNullOrEmpty
        }
        It 'should write a non-terminating error.' {
            $ErrorResult.Exception.Message | should match ("Failed to find a module metadata file at*")
        }
    }

    Context 'When a ModuleInfo object is passed with a manifest' {
        $result = Get-Module Microsoft.PowerShell.Management | Resolve-ModuleMetadataFile

        It 'should return the path with the module metadata folder.' {
            $result | should be (Convert-path "$pshome\Modules\Microsoft.PowerShell.Management\Microsoft.PowerShell.Management.psd1") 
        }
    }
     
}

Describe 'how Update-ModuleMetadataVersion responds when ' {
    Context 'when ' {
        $expected = ''
        $result = ''

        It "should call all the mocks" {
            Assert-VerifiableMocks
        }
        It 'should ' {
            $result | should be ($expected)
        }

    }
}