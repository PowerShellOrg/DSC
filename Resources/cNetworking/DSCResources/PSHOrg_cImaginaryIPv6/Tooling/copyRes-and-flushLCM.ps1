function pushRes
{
	[CmdletBinding()]
    Param ()
	clear-host
	$ApertureLabs = 'aperturelabs-8', 'aperturelabs-V'

	$jumpServer = '\\10.16.1.5\misc\DSC\dev\'

	Write-Host -Foreground Cyan "Copying to local Program Files\WindowsPowerShell\Modules"
	copy -Recurse -Force 'c:\users\adrianc\documents\github\dsc\resources\cNetworking' 'c:\program files\windowspowershell\modules\'
	Write-Host -Foreground Cyan "Copying to Jump Server"
	copy -Recurse -Force 'c:\users\adrianc\documents\github\dsc\resources\cNetworking' $jumpServer

	invoke-command -computer $ApertureLabs -argumentlist $jumpServer {
		set-executionPolicy RemoteSigned -Force;
		remove-item c:\windows\system32\configuration\*.mof;
		Write-Output "$(($env:COMPUTERNAME).toUpper()) -- Copying to Program Files"
		copy -Recurse -Force "$($args[0])\cNetworking" 'c:\program files\windowspowershell\modules\';
		write-output "$(($env:COMPUTERNAME).toUpper()) -- CLEARING MOF CACHE..";
		remove-item c:\windows\system32\configuration\*.* -verbose;
	    restart-service winmgmt -force -verbose }
    Write-Host -Foreground Green "All done. Targets ready to receive MOFs.`n"
}

pushRes #-verbose