#
# cWaitForSqlHAGroup: DSC resource to wait for existency of given name of Sql HA group, it checks the state of 
# the HA group with given interval until it exists or the number of retries is reached.
#


#
# The Get-TargetResource cmdlet.
#
function Get-TargetResource
{
    param
    (	
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $ClusterName,

	    [UInt64] $RetryIntervalSec = 10,
        [UInt32] $RetryCount = 10,

        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $InstanceName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$DomainCredential,
        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$SqlAdministratorCredential
    )

    $sa = $SqlAdministratorCredential.UserName
    $saPassword = $SqlAdministratorCredential.GetNetworkCredential().Password

    $bFound = Check-SQLHAGroup -InstanceName $InstanceName -Name $Name -sa $sa -saPassword $saPassword

    $returnValue = @{
        Name = $Name
        InstanceName = $InstanceName
        RetryIntervalSec = $RetryIntervalSec
        RetryCount = $RetryCount

        HAGroupExist = $bFound
    }
 
    $returnValue
}

#
# The Set-TargetResource cmdlet.
#
function Set-TargetResource
{
    param
    (	
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $ClusterName,

	    [UInt64] $RetryIntervalSec = 10,
        [UInt32] $RetryCount = 10,

        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $InstanceName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$DomainCredential,
        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$SqlAdministratorCredential
    )

    $bFound = $false
    Write-Verbose -Message "Checking for SQL HA Group $Name on instance $InstanceName ..."

    $sa = $SqlAdministratorCredential.UserName
    $saPassword = $SqlAdministratorCredential.GetNetworkCredential().Password

    for ($count = 0; $count -lt $RetryCount; $count++)
    {
        $bFound = Check-SQLHAGroupExist -ClusterName $ClusterName -Name $Name -domainCred $DomainCredential -sa $sa -saPassword $saPassword
        if ($bFound)
        {
            Write-Verbose -Message "Found SQL HA Group $Name on instance $InstanceName"
            break;
        }
        else
        {
            Write-Verbose -Message "SQL HA Group $Name on instance $InstanceName not found. Will retry again after $RetryIntervalSec sec"
            Start-Sleep -Seconds $RetryIntervalSec
        }
    }


    if (!$bFound)
    {
        throw "SQL HA Group $Name on instance $InstanceName not found afater $count attempt with $RetryIntervalSec sec interval"
    }
}

#
# The Test-TargetResource cmdlet.
#
function Test-TargetResource
{
    param
    (	
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $ClusterName,

	    [UInt64] $RetryIntervalSec = 10,
        [UInt32] $RetryCount = 10,

        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $InstanceName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$DomainCredential,
        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$SqlAdministratorCredential
    )

    Write-Verbose -Message "Checking for SQL HA Group $Name on instance $InstanceName ..."

    $sa = $SqlAdministratorCredential.UserName
    $saPassword = $SqlAdministratorCredential.GetNetworkCredential().Password

    $bFound = Check-SQLHAGroup -InstanceName $InstanceName -Name $Name -sa $sa -saPassword $saPassword
    if ($bFound)
    {
        Write-Verbose -Message "Found SQL HA Group $Name on instance $InstanceName"
        $true
    }
    else
    {
        Write-Verbose -Message "SQL HA Group $Name on instance $InstanceName not found"
        $false
    }
}


function Check-SQLHAGroup($InstanceName, $Name, $sa, $saPassword)
{
    $query = OSQL -S $InstanceName -U $sa -P $saPassword -Q "select count(name) from master.sys.availability_groups where name = '$Name'" -h-1
    [bool] [int] $query[0].Trim()
}

function Check-SQLHAGroupExist($ClusterName, $Name, $sa, $saPassword, $domainCred)
{
    $bHAGExist = $false

    try
    {
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $domainCred
        $nodes = Get-ClusterNode -Cluster $ClusterName
    }
    finally
    {
        if ($context)
        {
            $context.Undo()
            $context.Dispose()

            CloseUserToken($newToken)
        }
    }


    foreach ($node in $nodes.Name)
    {
        $instance = Get-SQLInstanceName -node $node -InstanceName $InstanceName
        $bCheck = Check-SQLHAGroup -InstanceName $instance -Name $Name -sa $sa -saPassword $saPassword
        if ($bCheck)
        {
            $bHAGExist = $true
            break
        }
    }

    $bHAGExist
}

function Get-ImpersonatetLib
{
    if ($script:ImpersonateLib)
    {
        return $script:ImpersonateLib
    }

    $sig = @'
[DllImport("advapi32.dll", SetLastError = true)]
public static extern bool LogonUser(string lpszUsername, string lpszDomain, string lpszPassword, int dwLogonType, int dwLogonProvider, ref IntPtr phToken);

[DllImport("kernel32.dll")]
public static extern Boolean CloseHandle(IntPtr hObject);
'@ 
   $script:ImpersonateLib = Add-Type -PassThru -Namespace 'Lib.Impersonation' -Name ImpersonationLib -MemberDefinition $sig 

   return $script:ImpersonateLib
    
}

function ImpersonateAs([PSCredential] $cred)
{
    [IntPtr] $userToken = [Security.Principal.WindowsIdentity]::GetCurrent().Token
    $userToken
    $ImpersonateLib = Get-ImpersonatetLib

    $bLogin = $ImpersonateLib::LogonUser($cred.GetNetworkCredential().UserName, $cred.GetNetworkCredential().Domain, $cred.GetNetworkCredential().Password, 
    9, 0, [ref]$userToken)
    
    if ($bLogin)
    {
        $Identity = New-Object Security.Principal.WindowsIdentity $userToken
        $context = $Identity.Impersonate()
    }
    else
    {
        throw "Can't Logon as User $cred.GetNetworkCredential().UserName."
    }
    $context, $userToken
}

function CloseUserToken([IntPtr] $token)
{
    $ImpersonateLib = Get-ImpersonatetLib

    $bLogin = $ImpersonateLib::CloseHandle($token)
    if (!$bLogin)
    {
        throw "Can't close token"
    }
}

function Get-PureInstanceName ($InstanceName)
{
    $list = $InstanceName.Split("\")
    if ($list.Count -gt 1)
    {
        $list[1]
    }
    else
    {
        "MSSQLSERVER"
    }
}

function Get-SQLInstanceName ($node, $InstanceName)
{
    $pureInstanceName = Get-PureInstanceName -InstanceName $InstanceName

    if ("MSSQLSERVER" -eq $pureInstanceName)
    {
        $node
    }
    else
    {
        $node + "\" + $pureInstanceName
    }
}

Export-ModuleMember -Function *-TargetResource

