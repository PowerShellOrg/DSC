$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.ps1", ".psm1")
$pathtosut = join-path $here $sut

iex ( gc $pathtosut -Raw )

#region Set-TargetResource
Describe 'how Set-TargetResource with Ensure = Absent responds' {
    $TargetResourceParams = @{
        Name = 'MyAdapter' 
        Description = 'MyDescribedAdapter' 
        Ensure = 'Absent'
    }

    Context 'when network adapter is named correctly and not in a team. ' {        
        Mock -verifiable -commandName Test-NetAdapterName -mockWith {$true}
        Mock -verifiable -commandName Rename-NetAdapterWithWait -mockWith {}        
        Mock -verifiable -commandName Remove-MismatchedNetLbfoTeamMember -mockWith {}
        Mock -verifiable -commandName Get-NetAdapter -mockWith {
            return ([pscustomobject]@{Name = 'MyAdapter'})
        }

        $result = Set-TargetResource @TargetResourceParams

        It 'should call Test-NetAdapterName' {
            Assert-MockCalled -commandName Test-NetAdapterName -times 1 -Exactly
        }
        It 'should call Rename-NetAdapterWithWait once, to rename to a temporary name' {
            Assert-MockCalled -commandName Rename-NetAdapterWithWait -times 1 -Exactly -parameterFilter {
                ($NewName -like 'Temp-*') -and ($Name -like $TargetResourceParams['Name'])
            }        
            Assert-MockCalled -commandName Rename-NetAdapterWithWait -times 0 -Exactly -parameterFilter {
                $NewName -like $TargetResourceParams['Name']
            }
        }
        It 'should call Remove-MismatchedNetLbfoTeamMember once, with MyAdapter as the name' {
            Assert-MockCalled -commandName Remove-MismatchedNetLbfoTeamMember -times 1 -Exactly -parameterFilter {
                $Name -like 'MyAdapter'
            }
        }
    }
    Context 'when network adapter is not named correctly and the name is not in use and it is not in a team. ' {        
        Mock -verifiable -commandName Test-NetAdapterName -mockWith {$false}
        Mock -verifiable -commandName Rename-NetAdapterWithWait -mockWith {}        
        Mock -verifiable -commandName Remove-MismatchedNetLbfoTeamMember -mockWith {}
        Mock -verifiable -commandName Get-NetAdapter -mockWith {
            return ([pscustomobject]@{Name = 'SomeOtherName'})
        }
        
        $result = Set-TargetResource @TargetResourceParams

        It 'should call Test-NetAdapterName' {
            Assert-MockCalled -commandName Test-NetAdapterName -times 1 -Exactly
        }
        It 'should not call Rename-NetAdapterWithWait' {            
            Assert-MockCalled -commandName Rename-NetAdapterWithWait -times 0 -Exactly
        }
        It 'should call Remove-MismatchedNetLbfoTeamMember once, with SomeOtherName as the name' {
            Assert-MockCalled -commandName Remove-MismatchedNetLbfoTeamMember -times 1 -Exactly -parameterFilter {
                $Name -like 'SomeOtherName'
            }
        }
    }  
}
Describe 'how Set-TargetResource with Ensure = Present responds' {
    $TargetResourceParams = @{
        Name = 'MyAdapter' 
        Description = 'MyDescribedAdapter' 
        Ensure = 'Present'
    }

    Context 'when network adapter is named correctly and not in a team. ' {        
        Mock -verifiable -commandName Test-NetAdapterName -mockWith {$true}
        Mock -verifiable -commandName Rename-NetAdapterWithWait -mockWith {}        
        
        $result = Set-TargetResource @TargetResourceParams

        It 'should call Test-NetAdapterName' {
            Assert-MockCalled -commandName Test-NetAdapterName -times 1 -Exactly
        }
        It 'should not call Rename-NetAdapterWithWait' {
            Assert-MockCalled -commandName Rename-NetAdapterWithWait -times 0 -Exactly             
        }
    }
    Context 'when network adapter is not named correctly and the name is not in use and it is not in a team. ' {        
        Mock -verifiable -commandName Test-NetAdapterName -mockWith {$false}
        Mock -verifiable -commandName Rename-NetAdapterWithWait -mockWith {}
        Mock -verifiable -commandName Get-NetAdapter -mockWith {
            return ([pscustomobject]@{Name = 'SomeOtherName'})
        }
        
        $result = Set-TargetResource @TargetResourceParams

        It 'should call Test-NetAdapterName' {
            Assert-MockCalled -commandName Test-NetAdapterName -times 1 -Exactly
        }
        It 'should call Rename-NetAdapterWithWait once for the desired name' {
            Assert-MockCalled -commandName Rename-NetAdapterWithWait -times 1 -Exactly -parameterFilter {
                $NewName -like $TargetResourceParams['Name']
            }
        }
    }  
    Context 'when network adapter is named correctly and it is not in a team. ' {        
        Mock -verifiable -commandName Test-NetAdapterName -mockWith {$true}
        Mock -verifiable -commandName Test-NetAdapterTeamMembership -mockWith {$true}      
        Mock -verifiable -commandName Remove-MismatchedNetLbfoTeamMember -mockWith {}
        Mock -verifiable -commandName New-NetLbfoTeamMember -mockWith {}
        
        $result = Set-TargetResource @TargetResourceParams 

        It 'should call Test-NetAdapterName and Test-NetAdapterTeamMembership' {
            Assert-MockCalled -commandName Test-NetAdapterName -times 1 -Exactly
            Assert-MockCalled -commandName Test-NetAdapterTeamMembership -times 1 -Exactly
        }
        It 'should not call Clear-MismatchedNetLbfoTeamMember and New-NetLbfoTeamMember' {
            Assert-MockCalled -commandName Remove-MismatchedNetLbfoTeamMember -times 0 -Exactly 
            Assert-MockCalled -commandName New-NetLbfoTeamMember -times 0 -Exactly 
        }
    }
    Context 'when network adapter is named correctly and is added to a team. ' {        
        Mock -verifiable -commandName Test-NetAdapterName -mockWith {$true}
        Mock -verifiable -commandName Test-NetAdapterTeamMembership -mockWith {$false}      
        Mock -verifiable -commandName Remove-MismatchedNetLbfoTeamMember -mockWith {}
        Mock -verifiable -commandName New-NetLbfoTeamMember -mockWith {}
        
        $result = Set-TargetResource @TargetResourceParams

        It 'should call Test-NetAdapterName and Test-NetAdapterTeamMembership' {
            Assert-MockCalled -commandName Test-NetAdapterName -times 1 -Exactly
            Assert-MockCalled -commandName Test-NetAdapterTeamMembership -times 1 -Exactly
        }
        It 'should call Clear-MismatchedNetLbfoTeamMember and New-NetLbfoTeamMember once each' {
            Assert-MockCalled -commandName Remove-MismatchedNetLbfoTeamMember -times 1 -Exactly 
            Assert-MockCalled -commandName New-NetLbfoTeamMember -times 1 -Exactly             
        }
    }
}
#endregion

#region Test-TargetResource
Describe 'how Test-TargetResource responds with Ensure = Present' {
    $TargetResourceParams = @{
        Name = 'MyAdapter' 
        Description = 'MyDescribedAdapter' 
        Ensure = 'Present'
    }
    Context 'when adapter is exists and is named correctly ' {
        Mock -verifiable -commandName Test-NetAdapterExists -mockWith {return $true}
        Mock -verifiable -commandName Test-NetAdapterName -mockWith {return $true}
        Mock -verifiable -commandName Test-NetAdapterTeamMembership -mockWith {return $true}

        $result = Test-TargetResource @TargetResourceParams

        It "should call all the mocks" {
            Assert-VerifiableMocks
        }
        It 'should return true' {
            $result | should be ($true)
        }
    }
    Context 'when adapter is exists and is not named correctly ' {
        Mock -verifiable -commandName Test-NetAdapterExists -mockWith {return $true}
        Mock -verifiable -commandName Test-NetAdapterName -mockWith {return $false}
        Mock -verifiable -commandName Test-NetAdapterTeamMembership -mockWith {return $true}

        $result = Test-TargetResource @TargetResourceParams

        It "should call all the mocks" {
            Assert-VerifiableMocks
        }
        It 'should return false' {
            $result | should be ($false)
        }
    }
    Context 'when adapter is does not exist ' {
        Mock -verifiable -commandName Test-NetAdapterExists -mockWith {throw 'No Adapter'}
        Mock -commandName Test-NetAdapterName -mockWith {return $false}
        Mock -commandName Test-NetAdapterTeamMembership -mockWith {return $true}

        $result = $false
        try 
        {
            Test-TargetResource @TargetResourceParams
        }
        catch 
        {
            $result = $true
        }
        
        It "should call all the mocks" {
            Assert-VerifiableMocks
        }
        It 'should return throw an error' {
            $result | should be ($true)
        }
    }
    Context 'when adapter is exists, is named correctly, and not in a team ' {
        Mock -verifiable -commandName Test-NetAdapterExists -mockWith {return $true}
        Mock -verifiable -commandName Test-NetAdapterName -mockWith {return $false}
        Mock -verifiable -commandName Test-NetAdapterTeamMembership -mockWith {return $true}

        $result = Test-TargetResource @TargetResourceParams

        It "should call all the mocks" {
            Assert-VerifiableMocks
        }
        It 'should return false' {
            $result | should be ($false)
        }
    }    
}

Describe 'how Test-TargetResource responds with Ensure = Absent' {
    $TargetResourceParams = @{
        Name = 'MyAdapter' 
        Description = 'MyDescribedAdapter' 
        Ensure = 'Absent'
    }
    Context 'when adapter is exists and is named correctly ' {
        Mock -verifiable -commandName Test-NetAdapterExists -mockWith {return $true}
        Mock -verifiable -commandName Test-NetAdapterName -mockWith {return $true}
        Mock -verifiable -commandName Test-NetAdapterTeamMembership -mockWith {return $true}

        $result = Test-TargetResource @TargetResourceParams

        It "should call all the mocks" {
            Assert-VerifiableMocks
        }
        It 'should return false' {
            $result | should be ($false)
        }
    }
    Context 'when adapter is exists and is not named correctly ' {
        Mock -verifiable -commandName Test-NetAdapterExists -mockWith {return $true}
        Mock -verifiable -commandName Test-NetAdapterName -mockWith {return $false}
        Mock -verifiable -commandName Test-NetAdapterTeamMembership -mockWith {return $true}

        $result = Test-TargetResource @TargetResourceParams

        It "should call all the mocks" {
            Assert-VerifiableMocks
        }
        It 'should return true' {
            $result | should be ($true)
        }
    }
    Context 'when adapter is does not exist ' {
        Mock -verifiable -commandName Test-NetAdapterExists -mockWith {throw 'No Adapter'}
        Mock -commandName Test-NetAdapterName -mockWith {return $false}
        Mock -commandName Test-NetAdapterTeamMembership -mockWith {return $true}

        $result = $false
        try 
        {
            Test-TargetResource @TargetResourceParams
        }
        catch 
        {
            $result = $true
        }
        
        It "should call all the mocks" {
            Assert-VerifiableMocks
        }
        It 'should thow an error' {
            $result | should be ($true)
        }
    }    
}

#endregion

#region Test-NetAdapterName
Describe 'how Test-NetAdapterName responds' {
    Context 'when adapter is in named correctly' {
        Mock -verifiable -commandName Get-NetAdapter -mockWith {
            return ([pscustomobject]@{InterfaceDescription = 'MyAdapter'})
        }
                    
        $result = Test-NetAdapterName -Name 'Adapter' -Description 'MyAdapter'

        It "should call all the mocks" {
            Assert-VerifiableMocks
        }
        It 'should return true' {
            $result | should be ($true)
        }
    }

    Context 'when wrong adapter has the name' {
        Mock -verifiable -commandName Get-NetAdapter -mockWith {
            return ([pscustomobject]@{InterfaceDescription = 'MyOtherAdapter'})
        }
                    
        $result = Test-NetAdapterName -Name 'Adapter' -Description 'MyAdapter'

        It "should call all the mocks" {
            Assert-VerifiableMocks
        }
        It 'should return false' {
            $result | should be ($false)
        }
    }

    Context 'when the adapter name is not present' {
        Mock -verifiable -commandName Get-NetAdapter -mockWith {}
                    
        $result = Test-NetAdapterName -Name 'Adapter' -Description 'MyAdapter'

        It "should call all the mocks" {
            Assert-VerifiableMocks
        }
        It 'should return false' {
            $result | should be ($false)
        }
    }
}
#endregion

#region Test-NetAdapterTeamMembership
Describe 'how Test-NetAdapterTeamMembership responds' {
    Context 'when adapter is in team' {
        Mock -commandName Get-NetLbfoTeamMember -mockWith {
            return ([pscustomobject]@{Team = 'MyTeam'})
        }        

        $result = Test-NetAdapterTeamMembership -TeamName 'MyTeam' -Name 'Something'
        
        It "should call all the mocks" {
            Assert-VerifiableMocks
        }
        It 'should be true' {
            $result | Should Be ($true)
        }
    }
    
    Context 'when adapter is in team and should not be' {
        Mock -commandName Get-NetLbfoTeamMember -mockWith {
            return ([pscustomobject]@{Team = 'MyOtherTeam'})
        }        

        $result = Test-NetAdapterTeamMembership -TeamName 'MyTeam' -Name 'Something'
        
        It "should call all the mocks" {
            Assert-VerifiableMocks
        }
        It 'should be false' {
            $result | Should Be ($false)
        }
    }

    Context 'when TeamName is empty' {
        
        $result = Test-NetAdapterTeamMembership -TeamName ''
        
        It 'should be true' {
            $result | Should Be ($true)
        }
    }
    
    Context 'when TeamName Does Not Exist' {
        Mock -verifiable -commandName Get-NetLbfoTeamMember -mockWith {}
        
        $result = Test-NetAdapterTeamMembership -TeamName 'NoTeamHere'

        It "should call all the mocks" {
            Assert-VerifiableMocks
        }
        It 'should be false' {
            $result | should be ($false)
        }
    }    
}
#endregion

#region Remove-MismatchedNetLbfoTeamMember
Describe 'how Remove-MismatchedNetLbfoTeamMember responds' {
    
    Context 'when adapter exists in desired team ' {
        Mock -commandName Remove-NetLbfoTeamMember -mockWith {}
        Mock -commandName Remove-NetLbfoTeam -mockWith {}
        Mock -commandName Get-NetLbfoTeamMember -mockWith {
            return ([pscustomobject]@{Name = 'MyAdapter';Team = 'MyTeam'})
        }
        
        Remove-MismatchedNetLbfoTeamMember -Name 'MyAdapter' -Team 'MyTeam'

        It "should not call Remove-NetLbfoTeamMember or Remove-NetLbfoTeam" {
            Assert-MockCalled -commandName Remove-NetLbfoTeamMember -times 0 -Exactly
            Assert-MockCalled -commandName Remove-NetLbfoTeam -times 0 -Exactly
        }
    }
    Context 'when adapter exists in desired team but RemoveFromAll is specfied' {
        Mock -commandName Remove-NetLbfoTeamMember -mockWith {}
        Mock -commandName Remove-NetLbfoTeam -mockWith {}
        Mock -commandName Get-NetLbfoTeamMember -mockWith {
            return ([pscustomobject]@{Name = 'MyAdapter';Team = 'MyTeam'})
        }
        
        Remove-MismatchedNetLbfoTeamMember -Name 'MyAdapter' -Team 'MyTeam' -RemoveFromAll

        It "should call Remove-NetLbfoTeamMember and not Remove-NetLbfoTeam" {
            Assert-MockCalled -commandName Remove-NetLbfoTeamMember -times 1 -Exactly
            Assert-MockCalled -commandName Remove-NetLbfoTeam -times 0 -Exactly
        }
    }
    Context 'when adapter exists in different team and is only Nic in that team.' {
        Mock -commandName Remove-NetLbfoTeamMember -mockWith { throw 'not me' }
        Mock -commandName Remove-NetLbfoTeam -mockWith {}
        Mock -commandName Get-NetLbfoTeamMember -mockWith {
            return ([pscustomobject]@{Name = 'MyAdapter';Team = 'MyOtherTeam'})
        }
        
        Remove-MismatchedNetLbfoTeamMember -Name 'MyAdapter' -Team 'MyTeam' 

        It "should call Remove-NetLbfoTeamMember, error, and Remove-NetLbfoTeam" {
            Assert-MockCalled -commandName Remove-NetLbfoTeamMember -times 1 -Exactly 
            Assert-MockCalled -commandName Remove-NetLbfoTeam -times 1 -Exactly -parameterFilter {
                $Name -like 'MyOtherTeam'
            }
        }
    }
}
#endregion

#region New-NetLbfoTeamMember
Describe 'how New-NetLbfoTeamMember responds' {
    Context 'when the team exists' {
        Mock -commandName Get-NetLbfoTeam -mockWith { return 1}
        Mock -commandName Add-NetLbfoTeamMember -mockWith {}
        Mock -commandName New-NetLbfoTeam -mockWith {}

        New-NetLbfoTeamMember -Name 'MyAdapter' -TeamName 'MyTeam'

        It 'should call Add-NetLbfoTeamMember and not New-NetLbfoTeam' {
            Assert-MockCalled -commandName Add-NetLbfoTeamMember -times 1 -Exactly 
            Assert-MockCalled -commandName New-NetLbfoTeam -times 0 -Exactly 
        }
    }
    Context 'when the team does not exist' {
        Mock -commandName Get-NetLbfoTeam -mockWith {}
        Mock -commandName Add-NetLbfoTeamMember -mockWith {}
        Mock -commandName New-NetLbfoTeam -mockWith {}

        New-NetLbfoTeamMember -Name 'MyAdapter' -TeamName 'MyTeam'

        It 'should call New-NetLbfoTeam and not Add-NetLbfoTeamMember' {
            Assert-MockCalled -commandName Add-NetLbfoTeamMember -times 0 -Exactly 
            Assert-MockCalled -commandName New-NetLbfoTeam -times 1 -Exactly 
        }
    }
}
#endregion


