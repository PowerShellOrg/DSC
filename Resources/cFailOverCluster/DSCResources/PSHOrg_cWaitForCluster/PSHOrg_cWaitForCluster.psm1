#
# xWaitForCluster: DSC Resource that will wait for given name of Cluster, it checks the state of the cluster for given # interval until the cluster is found or the number of retries is reached.
#
# 


#
# The Get-TargetResource cmdlet.
#
function Get-TargetResource
{
    param
    (	
        [parameter(Mandatory)][string] $Name,

        [UInt64] $RetryIntervalSec = 10,
        [UInt32] $RetryCount = 50
    )

    @{
        Name = $Name
        RetryIntervalSec = $RetryIntervalSec
        RetryCount = $RetryCount
    }
}

#
# The Set-TargetResource cmdlet.
#
function Set-TargetResource
{
    param
    (	
        [parameter(Mandatory)][string] $Name,

        [UInt64] $RetryIntervalSec = 10,
        [UInt32] $RetryCount = 50
    )

    $clusterFound = $false
    Write-Verbose -Message "Checking for cluster $Name ..."

    for ($count = 0; $count -lt $RetryCount; $count++)
    {
        try
        {
            $ComputerInfo = Get-WmiObject Win32_ComputerSystem
            if (($ComputerInfo -eq $null) -or ($ComputerInfo.Domain -eq $null))
            {
                Write-Verbose -Message "Can't find machine's domain name"
                break;
            }

            $cluster = Get-Cluster -Name $Name -Domain $ComputerInfo.Domain

            if ($cluster -ne $null)
            {
                Write-Verbose -Message "Found cluster $Name"
                $clusterFound = $true

                break;
            }
            
        }
        catch
        {
             Write-Verbose -Message "Cluster $Name not found. Will retry again after $RetryIntervalSec sec"
        }
            
        Write-Verbose -Message "Cluster $Name not found. Will retry again after $RetryIntervalSec sec"
        Start-Sleep -Seconds $RetryIntervalSec
    }

    if (! $clusterFound)
    {
        throw "Cluster $Name not found after $count attempts with $RetryIntervalSec sec interval"
    }
}

#
# The Test-TargetResource cmdlet.
#
function Test-TargetResource
{
    param
    (	
        [parameter(Mandatory)][string] $Name,

        [UInt64] $RetryIntervalSec = 10,
        [UInt32] $RetryCount = 50
    )

    Write-Verbose -Message "Checking for Cluster $Name ..."

    try
    {
        $ComputerInfo = Get-WmiObject Win32_ComputerSystem
        if (($ComputerInfo -eq $null) -or ($ComputerInfo.Domain -eq $null))
        {
            Write-Verbose -Message "Can't find machine's domain name"
            $false
        }

        $cluster = Get-Cluster -Name $Name -Domain $ComputerInfo.Domain
        if ($cluster -eq $null)
        {
            Write-Verbose -Message "Cluster $Name not found in domain $ComputerInfo.Domain"
            $false
        }
        else
        {
            Write-Verbose -Message "Found cluster $Name"
            $true
        }
    }
    catch
    {
        Write-Verbose -Message "Cluster $Name not found"
        $false
    }
}


