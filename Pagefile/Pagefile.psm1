
# Fallback message strings in en-US
DATA localizedData
{
    # same as culture = "en-US"
    ConvertFrom-StringData @'    
AutomaticPageFileConfigured=The page file is set to automatic configuration.
PageFileStaticallyConfigured=The page file is statically configured with the initial size of {0} and a maximum size of {1}.
DisabledAutomaticPageFile=The automatic page file configuration is disabled.
RebootRequired=A reboot is required to finalize the changes to the page file.
InitialSizeDifferent=Configured Initial Size {0} different than Desired size {1}.
MaximumSizeDifferent=Configured Maximum Size {0} different than Desired size {1}.
'@
}

Import-LocalizedData LocalizedData -filename PagefileProvider.psd1

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
        [parameter(Mandatory = $true)]        
        [long]
        $InitialSize,
        [parameter(Mandatory = $true)]        
        [long]
        $MaximumSize,
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    #Needs to return a hashtable that returns the current
    #status of the configuration component
    $ComputerSystem = Get-WmiObject win32_computersystem -EnableAllPrivileges
    if ($ComputerSystem.AutomaticManagedPageFile)
    {
        Write-Verbose  $LocalizedData.AutomaticPageFileConfigured
        $Configuration = @{
            Ensure = 'Absent'
        }
    }
    else
    {        
        $PageFileSetting = Get-WmiObject Win32_PageFileSetting -EnableAllPrivileges
        $Configuration = @{
            Ensure = 'Present'
            InitialSize = $PageFileSetting.InitialSize * 1mb
            MaximumSize = $PageFileSetting.MaximumSize * 1mb
        }

        Write-Verbose ($LocalizedData.PageFileStaticallyConfigured -f $Configuration.InitialSize, $Configuration.MaximumSize)
    }
    return $Configuration
}

function Set-TargetResource
{
    param (
        [parameter(Mandatory = $true)]        
        [long]
        $InitialSize,
        [parameter(Mandatory = $true)]        
        [long]
        $MaximumSize,
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )
    if ($Ensure -like 'Present')
    {
        
        $ComputerSystem = Get-WmiObject win32_computersystem -EnableAllPrivileges 
        if ($ComputerSystem.AutomaticManagedPageFile)
        {
            Write-Verbose  $LocalizedData.AutomaticPageFileConfigured
            $ComputerSystem.AutomaticManagedPageFile = $false
            $ComputerSystem.Put() | Out-Null
            Write-Verbose $LocalizedData.DisabledAutomaticPageFile
        }
           
        $PageFileSetting = Get-WmiObject Win32_PageFileSetting -EnableAllPrivileges 
        $PageFileSetting.InitialSize = $InitialSize / 1MB
        $PageFileSetting.MaximumSize = $MaximumSize / 1MB                
        $PageFileSetting.put() | out-null

        Write-Verbose ($LocalizedData.PageFileStaticallyConfigured -f $InitialSize, $MaximumSize)
    }
    else
    {
        $ComputerSystem = Get-WmiObject win32_computersystem -EnableAllPrivileges 
        if (-not $ComputerSystem.AutomaticManagedPageFile)
        {
            $ComputerSystem.AutomaticManagedPageFile = $true
            $ComputerSystem.Put() | Out-Null
            Write-Verbose  $LocalizedData.AutomaticPageFileConfigured
        }
    }
    
    Write-Verbose $LocalizedData.RebootRequired
    $global:DSCMachineStatus = 1

}

function Test-TargetResource
{
    [OutputType([boolean])]
    param (
        [parameter(Mandatory = $true)]        
        [long]
        $InitialSize,
        [parameter(Mandatory = $true)]        
        [long]
        $MaximumSize,
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    $Valid = $true
    $ComputerSystem = Get-WmiObject win32_computersystem -EnableAllPrivileges
    $PageFileSetting = Get-WmiObject Win32_PageFileSetting -EnableAllPrivileges
    if ($Ensure -like 'Present')
    {
         
        if ($ComputerSystem.AutomaticManagedPageFile)
        {
            Write-Verbose  $LocalizedData.AutomaticPageFileConfigured
            $Valid = $Valid -and $false
        }
        
           
        if ($PageFileSetting -ne $null)
        {
            if (-not ($PageFileSetting.InitialSize -eq ($InitialSize / 1MB)))
            {
                Write-Verbose ($LocalizedData.InitialSizeDifferent -f ($PageFileSetting.InitialSize * 1mb), $InitialSize)
                $Valid = $Valid -and $false
            }

            if (-not ($PageFileSetting.MaximumSize -eq ($MaximumSize / 1MB)))
            {
                Write-Verbose ($LocalizedData.MaximumSizeDifferent -f ($PageFileSetting.MaximumSize * 1mb), $MaximumSize)
                $Valid = $Valid -and $false
            }
        }
    }
    else
    {
        if (-not $ComputerSystem.AutomaticManagedPageFile)
        {
            Write-Verbose $LocalizedData.DisabledAutomaticPageFile
            $Valid = $Valid -and $false
        }
    }

    #Needs to return a boolean  
    return $valid
}