# Fallback message strings in en-US
DATA localizedData
{
    # same as culture = "en-US"
    ConvertFrom-StringData @'    
    CheckingCurrentExecutionPolicy=Checking for the existing execution policy.
    ExecutionPolicyFound=Located an execution policy of {0}.
    ExecutionPolicyNotFound=Did not find an execution policy of {0}.
    ApplyingExecutionPolicy=Starting to apply {0} as the execution policy.
    AppliedExecutionPolicy=Applied {0} as the execution policy.
    AnErrorOccurred=An error occurred trying to apply {0} as the execution policy: {1}.
    InnerException=Nested error trying to apply {0} as the execution policy: {1}.
    DoesNotApply=Absent does not apply to this configuration item.
'@
}

if (Test-Path $PSScriptRoot\en-us)
{
    Import-LocalizedData LocalizedData -filename SetExecutionPolicyProvider.psd1
}

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
        [parameter(Mandatory = $true)]
        [ValidateSet('Restricted', 'AllSigned', 'RemoteSigned', 'Unrestricted')]
        [string]
        $Name,
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    $Configuration = @{
            Name = $Name
    }

    Write-Verbose $LocalizedData.CheckingCurrentExecutionPolicy
    $CurrentExecutionPolicy = Get-ExecutionPolicy
    if ($Name -like $CurrentExecutionPolicy)
    {
        Write-Verbose ($LocalizedData.ExecutionPolicyFound -f $Name)
        $Configuration.Ensure = 'Present'
    }
    else
    {
        Write-Verbose ($LocalizedData.ExecutionPolicyNotFound -f $Name)
        $Configuration.Ensure = 'Absent'
    }

    return $Configuration
}

function Set-TargetResource
{
    param (
        [parameter(Mandatory = $true)]
        [ValidateSet('Restricted', 'AllSigned', 'RemoteSigned', 'Unrestricted')]
        [string]
        $Name,
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    if ($Ensure -like 'Present')
    {
        Write-Verbose ($LocalizedData.ApplyingExecutionPolicy -f $Name)
        try
        {
            Set-ExecutionPolicy -ExecutionPolicy $Name -Force -ErrorAction Stop
            Write-Verbose ($LocalizedData.AppliedExecutionPolicy -f $Name)
        }
        catch 
        {    
            $exception = $_    
            Write-Verbose ($LocalizedData.AnErrorOccurred -f $name, $exception.message)
            while ($exception.InnerException -ne $null)
            {
                $exception = $exception.InnerException
                Write-Verbose ($LocalizedData.InnerException -f $name, $exception.message)
            }
        }
    }
    else
    {
        Write-Verbose $LocalizedData.DoesNotApply
    }

    
}

function Test-TargetResource
{
    [OutputType([boolean])]
    param (
        [parameter(Mandatory = $true)]
        [ValidateSet('Restricted', 'AllSigned', 'RemoteSigned', 'Unrestricted')]
        [string]
        $Name,
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    switch (Get-ExecutionPolicy)
    {
        {($Name -like $_) -and ($Ensure -like 'Present')}   { 
                                                                Write-Verbose ($LocalizedData.ExecutionPolicyFound -f $name)
                                                                return $true 
                                                            }
    
        default                                             { 
                                                                Write-Verbose ($LocalizedData.ExecutionPolicyNotFound -f $Name)
                                                                return $false 
                                                            }
    }
}


