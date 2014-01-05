configuration Sample_cVhd_DiffVhd
{
    param
    (
        [string[]]$NodeName = 'localhost',
        
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$ParentPath,
        
        [ValidateSet("Vhd","Vhdx")]
        [string]$Generation = "Vhd",

        [ValidateSet("Present","Absent")]
        [string]$Ensure = "Present"    
    )

    Import-DscResource -module cHyper-V

    Node $NodeName
    {
        # Install HyperV feature, if not installed - Server SKU only
        WindowsFeature HyperV
        {
            Ensure = 'Present'
            Name   = 'Hyper-V'
        }
        
        cVhd DiffVhd
        {
            Ensure     = $Ensure
            Name       = $Name
            Path       = $Path
            ParentPath = $ParentPath
            Generation = $Generation
            DependsOn  = '[WindowsFeature]HyperV'
        }
    }
}