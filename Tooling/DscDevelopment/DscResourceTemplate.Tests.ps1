$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.ps1", ".psm1")
$pathtosut = join-path $here $sut

iex (gc $pathtosut -Raw)

Describe 'how Test-TargetResource responds' {
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

Describe 'how Set-TargetResource responds' {
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


