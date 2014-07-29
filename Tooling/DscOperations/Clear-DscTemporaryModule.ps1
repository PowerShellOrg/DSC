function Clear-DscTemporaryModule {
    <#
        .Synopsis
            Deletes any directories in $env:programfiles\windowspowershell\modules\ whose names end in "_tmp".
        .Description
            Deletes any directories in $env:programfiles\windowspowershell\modules\ whose names end in "_tmp".
            This is due to a failure of the LCM in WMF4 to properly clean up modules with resources when a newer module is retrieved from a pull server.
        .Example
            Clear-DscTemporaryModule -ComputerName OR-WEB01
    #>
	param (
		#Name of the computer(s) to target.
		[Parameter(
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true,
			Position='0'
		)]
		[ValidateNotNullOrEmpty()]            
        [Alias('__Server', 'Name')]
		[string[]]
		$ComputerName = $env:COMPUTERNAME,

        #Alternate credentials to use in connecting to the remote computer(s).
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

