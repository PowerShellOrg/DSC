. $psscriptroot\Assert-DestinationDirectory.ps1
. $psscriptroot\Clear-CachedDscResource.ps1
. $psscriptroot\Clear-InstalledDscResource.ps1
. $psscriptroot\Compress-DscResourceModule.ps1
. $psscriptroot\Copy-CurrentDscResource.ps1
. $psscriptroot\DscResourceWmiClass.ps1
. $psscriptroot\Invoke-DscBuild.ps1
. $psscriptroot\Invoke-DscConfiguration.ps1
. $psscriptroot\Invoke-DscResourceUnitTest.ps1
. $psscriptroot\New-DscChecksumFile.ps1
. $psscriptroot\New-DscZipFile.ps1
. $psscriptroot\Publish-DscConfiguration.ps1
. $psscriptroot\Publish-DscResourceModule.ps1
. $psscriptroot\Test-DscResourceIsValid.ps1
. $psscriptroot\Where-DscResource.ps1

$DscBuildParameters = $null

Clear-CachedDscResource 