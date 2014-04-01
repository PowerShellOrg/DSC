function Get-DscResourceWmiClass {
    param (
        [parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Class
    )
    begin {
        $DscNamespace = "root/Microsoft/Windows/DesiredStateConfiguration"        
    }
    process {        
        Get-wmiobject -Namespace $DscNamespace -list @psboundparameters
    }
}

function Remove-DscResourceWmiClass {
    param (
        [parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [alias('Name')]
        [string]
        $ResourceType
    )
    begin {
        $DscNamespace = "root/Microsoft/Windows/DesiredStateConfiguration"        
    }
    process {        
        (Get-wmiobject -Namespace $DscNamespace -list -Class $ResourceType).psbase.delete()
    }
}