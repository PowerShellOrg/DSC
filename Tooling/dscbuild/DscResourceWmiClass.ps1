function Get-DscResourceWmiClass {
    <#
        .Synopsis
            Retrieves WMI classes from the DSC namespace.
        .Description
            Retrieves WMI classes from the DSC namespace.
        .Example
            Get-DscResourceWmiClass -Class tmp*
        .Example
            Get-DscResourceWmiClass -Class 'MSFT_UserResource'
    #>
    param (
        #The WMI Class name search for.  Supports wildcards.
        [parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Name')]
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
    <#
        .Synopsis
            Removes a WMI class from the DSC namespace.
        .Description
            Removes a WMI class from the DSC namespace.
        .Example
            Get-DscResourceWmiClass -Class tmp* | Remove-DscResourceWmiClass
        .Example
            Remove-DscResourceWmiClass -Class 'tmpD460'
            
    #>
    param (
        #The WMI Class name to remove.  Supports wildcards.
        [parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [alias('Name')]
        [string]
        $ResourceType
    )
    begin {
        $DscNamespace = "root/Microsoft/Windows/DesiredStateConfiguration"        
    }
    process { 
        #Have to use WMI here because I can't find how to delete a WMI instance via the CIM cmdlets.       
        (Get-wmiobject -Namespace $DscNamespace -list -Class $ResourceType).psbase.delete()
    }
}

