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

describe 'how Add-NodeRoleFromServiceConfigurationData works' {
    context 'when ' {}
}