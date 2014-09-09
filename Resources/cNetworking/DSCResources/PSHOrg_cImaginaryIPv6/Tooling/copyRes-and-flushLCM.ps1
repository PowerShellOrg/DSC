clear-host
invoke-command -computer aperturelabs-8, aperturelabs-V { 
	set-executionPolicy RemoteSigned -Force ; restart-service winmgmt -force -verbose ; `
	remove-item -verbose c:\windows\system32\configuration\*.mof ; `
	copy -Recurse -Force \\10.16.1.5\misc\DSC\RES\cImaginaryIPv6 'c:\program files\windowspowershell\modules\' -Verbose ; `
	remove-module * -verbose }                                                                                                  