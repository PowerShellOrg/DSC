#
# xCluster: DSC resource to configure a Windows Cluster. If the cluster does not exist, it will create one in the 
# domain and assign the StaticIPAddress to the cluster. Then, it will add current node to the cluster.
#

#
# The Get-TargetResource cmdlet.
#
function Get-TargetResource
{
    param
    (	
        [parameter(Mandatory)]
        [string] $Name,

        [parameter(Mandatory)]
        [string] $StaticIPAddress,
        
        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential
    )

    $ComputerInfo = Get-WmiObject Win32_ComputerSystem
    if (($ComputerInfo -eq $null) -or ($ComputerInfo.Domain -eq $null))
    {
        throw "Can't find machine's domain name"
    }
    
    try
    {
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $cluster = Get-Cluster -Name $Name -Domain $ComputerInfo.Domain
        if ($null -eq $cluster)
        {
            throw "Can't find the cluster $Name"
        }

        $address = Get-ClusterGroup -Cluster $Name -Name "Cluster IP Address" | Get-ClusterParameter "Address"
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

    $retvalue = @{
        Name = $Name
        IPAddress = $address.Value
    }
}

#
# The Set-TargetResource cmdlet.
#
function Set-TargetResource
{
    param
    (	
        [parameter(Mandatory)]
        [string] $Name,

        [parameter(Mandatory)]
        [string] $StaticIPAddress,
        
        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential
    )

    $bCreate = $true

    Write-Verbose -Message "Checking if Cluster $Name is present ..."
    try
    {
        $ComputerInfo = Get-WmiObject Win32_ComputerSystem
        if (($ComputerInfo -eq $null) -or ($ComputerInfo.Domain -eq $null))
        {
            throw "Can't find machine's domain name"
        }

        $cluster = Get-Cluster -Name $Name -Domain $ComputerInfo.Domain

        if ($cluster)
        {
            $bCreate = $false     
        }
    }
    catch
    {
        $bCreate = $true

    }

    try
    {
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential  

        if ($bCreate)
        {
            Write-Verbose -Message "Cluster $Name is NOT present"

            New-Cluster -Name $Name -Node $env:COMPUTERNAME -StaticAddress $StaticIPAddress -NoStorage -Force

            Write-Verbose -Message "Created Cluster $Name"
        }
        else
        {
            Write-Verbose -Message "Add node to Cluster $Name ..."

            Write-Verbose -Message "Add-ClusterNode $env:COMPUTERNAME to cluster $Name"
                           
            $list = Get-ClusterNode -Cluster $Name
            foreach ($node in $list)
            {
                if ($node.Name -eq $env:COMPUTERNAME)
                {
                    if ($node.State -eq "Down")
                    {
                        Write-Verbose -Message "node $env:COMPUTERNAME was down, need remove it from the list."

                        Remove-ClusterNode $env:COMPUTERNAME -Cluster $Name -Force
                    }
                }
            }

            Add-ClusterNode $env:COMPUTERNAME -Cluster $Name
            
            Write-Verbose -Message "Added node to Cluster $Name"
        
        }
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
}

# 
# Test-TargetResource
#
# The code will check the following in order: 
# 1. Is machine in domain?
# 2. Does the cluster exist in the domain?
# 3. Is the machine is in the cluster's nodelist?
# 4. Does the cluster node is UP?
#  
# Function will return FALSE if any above is not true. Which causes cluster to be configured.
# 
function Test-TargetResource  
{
    param
    (	
        [parameter(Mandatory)]
        [string] $Name,

        [parameter(Mandatory)]
        [string] $StaticIPAddress,
        
        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential
    )

    $bRet = $false

    Write-Verbose -Message "Checking if Cluster $Name is present ..."
    try
    {

        $ComputerInfo = Get-WmiObject Win32_ComputerSystem
        if (($ComputerInfo -eq $null) -or ($ComputerInfo.Domain -eq $null))
        {
            Write-Verbose -Message "Can't find machine's domain name"
            $bRet = $false
        }
        else
        {
            try
            {
                ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
         
                $cluster = Get-Cluster -Name $Name -Domain $ComputerInfo.Domain

                Write-Verbose -Message "Cluster $Name is present"

                if ($cluster)
                {
                    Write-Verbose -Message "Checking if the node is in cluster $Name ..."
         
                    $allNodes = Get-ClusterNode -Cluster $Name

                    foreach ($node in $allNodes)
                                                                        {
                    if ($node.Name -eq $env:COMPUTERNAME)
                    {
                        if ($node.State -eq "Up")
                        {
                            $bRet = $true
                        }
                        else
                        {
                             Write-Verbose -Message "Node is in cluster $Name but is NOT up, treat as NOT in cluster."
                        }

                        break
                    }
                }

                    if ($bRet)
                    {
                        Write-Verbose -Message "Node is in cluster $Name"
                    }
                    else
                    {
                        Write-Verbose -Message "Node is NOT in cluster $Name"
                    }
                }
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
        }
    }
    catch
    {
        Write-Verbose -Message "Cluster $Name is NOT present with Error $_.Message"
    }

    $bRet
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


