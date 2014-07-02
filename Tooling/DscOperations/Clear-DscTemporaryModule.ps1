function Clear-DscTemporaryModule {
	param (
		
		[Parameter(
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true,
			Position='0'
		)]
		[ValidateNotNullOrEmpty()]            
        [Alias('__Server', 'Name')]
		[string[]]
		$ComputerName = $env:COMPUTERNAME,


		[Parameter(
			Position=2
		)]
		[System.Management.Automation.Credential()]
		$Credential = [System.Management.Automation.PSCredential]::Empty
	)

	process {
		invoke-command @psboundparameters {
            dir $env:ProgramFiles\windowspowershell\modules\*_tmp | 
                remove-item -recurse -force
            get-process WmiPrvSE | stop-process -force 
        }
    }
}

