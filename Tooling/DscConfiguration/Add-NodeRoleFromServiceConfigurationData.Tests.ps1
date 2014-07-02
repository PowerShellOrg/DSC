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

describe 'how Add-NodeRoleFromServiceConfigurationData works' {
    context 'when ' {}
}

