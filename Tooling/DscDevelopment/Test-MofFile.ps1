function Test-MofFile {
	param (
		[parameter(Mandatory,Position=0)]
		$NodeId,
        [parameter(Position=1)]
        $ConfigurationPath = 'd:\temp\cimschema'
	)
	Get-Process WmiPrvSE | Stop-Process -Force
	start-job -argumentlist $NodeId -scriptblock {
		param ($NodeId)
		ipmo dscdevelopment
		reset-cimclasscache
		dir 'C:\Program Files\WindowsPowerShell\Modules\' -Recurse -Include *.schema.mof | Add-CachedCimClass
		Import-CimInstances -MofInstanceFilePath (join-path $ConfigurationPath "$NodeId.mof")
	} | receive-job -wait
}


