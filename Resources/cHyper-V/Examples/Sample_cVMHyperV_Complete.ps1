configuration Sample_cVMHyperV_Complete
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
        [Uint64]$MaximumMemory,

        [Parameter(Mandatory)]
        [String]$SwitchName,

        [Parameter(Mandatory)]
        [String]$Path,

        [Parameter(Mandatory)]
        [Uint32]$ProcessorCount,

        [ValidateSet('Off','Paused','Running')]
        [String]$State = 'Off',

        [Switch]$WaitForIP
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

        # Ensures a VM with all the properties
        cVMHyperV NewVM
        {
            Ensure          = 'Present'
            Name            = $VMName
            VhdPath         = $VhdPath
            SwitchName      = $SwitchName
            State           = $State
            Path            = $Path
            Generation      = $VhdPath.Split('.')[-1]
            StartupMemory   = $StartupMemory
            MinimumMemory   = $MinimumMemory
            MaximumMemory   = $MaximumMemory
            ProcessorCount  = $ProcessorCount
            MACAddress      = $MACAddress
            RestartIfNeeded = $true
            WaitForIP       = $WaitForIP 
            DependsOn       = '[WindowsFeature]HyperV'
        }
    }
}