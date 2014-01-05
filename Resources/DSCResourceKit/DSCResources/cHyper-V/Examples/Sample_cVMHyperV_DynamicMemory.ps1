configuration Sample_cVMHyperV_DynamicMemory
{
    param
    (
        [string[]]$NodeName = 'localhost',

        [Parameter(Mandatory)]
        [string]$VMName,
        
        [Parameter(Mandatory)]
        [string]$VhdPath,

        [Parameter(Mandatory)]
        [Uint64]$StartupMemory,

        [Parameter(Mandatory)]
        [Uint64]$MinimumMemory,

        [Parameter(Mandatory)]
        [Uint64]$MaximumMemory
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

        # Ensures a VM with dynamic memory
        cVMHyperV NewVM
        {
            Ensure        = 'Present'
            Name          = $VMName
            VhdPath       = $VhdPath
            Generation    = $VhdPath.Split('.')[-1]
            StartupMemory = $StartupMemory
            MinimumMemory = $MinimumMemory
            MaximumMemory = $MaximumMemory
            DependsOn     = '[WindowsFeature]HyperV'
        }
    }
}