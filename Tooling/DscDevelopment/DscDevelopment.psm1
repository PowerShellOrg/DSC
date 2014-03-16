. $PSScriptRoot\New-DscResourceFromModule.ps1
. $PSScriptRoot\New-MofFile.ps1
. $PSScriptRoot\Test-DscBuild.ps1
. $PSScriptRoot\New-DscNodeMetadata.ps1
. $PSScriptRoot\New-xDscCompositeResource.ps1


function Get-Hashtable
{
    # Path to PSD1 file to evaluate
    param (
        [parameter(
            Position = 0,
            ValueFromPipelineByPropertyName,
            Mandatory
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('FullName')]
        [string]
        $Path
    ) 
    process 
    {
        Write-Verbose "Loading data from $Path."
        invoke-expression "DATA { $(get-content -raw -path $path) }"
    }    
}



function Remove-DscResource {
    param (
        [parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
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