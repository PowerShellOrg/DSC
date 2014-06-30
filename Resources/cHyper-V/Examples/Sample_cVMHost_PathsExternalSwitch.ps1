configuration??Sample_cVMHost??
{
    WindowsFeature hypervRole
    {
        Ensure = 'Present'
        Name = 'Hyper-V'
    }
    
    WindowsFeature hypervManagement
    {
        Ensure = 'Present'
        Name = 'Hyper-V-PowerShell'
        DependsOn = '[WindowsFeature]hypervRole'

    }

Import-DscResource -module cHyper-V

    PSHOrg_cVMHost hostSettings
    {
        VMHost = 'localhost'
        Ensure = 'Present'
        VirtualDiskPath = 'C:\users\public\VHDs'
        VirtualMachinePath = 'C:\users\public\VMConfig'
        VirtualMachineMigration = $true
        EnhancedSessionMode = $false
        # ensure the Hyper-V PowerShell module is added
        DependsOn = '[WindowsFeature]hypervManagement'
    }   

    Import-DscResource -module xHyper-V

    xVMSwitch ExternalSwitch
    {
        Ensure = 'Present'
        Name = 'VMs' 
        Type = 'External'
        NetAdapterName = (Get-NetAdapter)[0].Name
            AllowManagementOS = $true
    }
    
}

