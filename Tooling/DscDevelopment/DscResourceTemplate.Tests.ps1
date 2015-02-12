$modulePath = $PSCommandPath -replace '\.Tests\.ps1$', '.psm1'
$prefix = [guid]::NewGuid().Guid -replace '[^a-f\d]'

$module = $null

try
{
    $module = Import-Module $modulePath -PassThru -Prefix $prefix -ErrorAction Stop

    Describe 'Get-TargetResource' {
        It 'Tests the example module Get function' {
            $name = 'Something'
            $hashtable = & "Get-${prefix}TargetResource" -Name $name

            $hashtable.PSBase.Count | Should Be 2
            $hashtable['Name'] | Should Be $name
            $hashtable['Ensure'] | Should Be 'Absent'
        }
    }

    Describe 'Test-TargetResource' {
        It 'Tests the example module Test function' {
            $result = & "Test-${prefix}TargetResource" -Name SomeName
            $result | Should Be $true
        }
    }

    Describe 'Set-TargetResource' {
        It 'Tests the example module Set function' {
            $scriptBlock = { & "Set-${prefix}TargetResource" -Name SomeName }
            $scriptBlock | Should Not Throw
        }
    }
}
finally
{
    if ($module) { Remove-Module -ModuleInfo $module }
}
