# Snobu_ImaginaryIPv6 DSC Resource
# Enable/Disable IPv6 Transition Mechanism: 6to4, Teredo, ISATAP

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
	param
	(	
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Default","Enabled","Disabled")]
        [String]$SixToFour,
        
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Automatic","Client","Default","Disabled","Enterpriseclient","Server")]
        [String]$Teredo,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Default","Enabled","Disabled")]
        [String]$ISATAP
	)
	  
    @{
        SixToFour = (Get-Net6to4Configuration).State
        Teredo = (Get-NetTeredoConfiguration).Type
        ISATAP = (Get-NetIsatapConfiguration).State
	}
} #Get-TargetResource


function Set-TargetResource
{
    [CmdletBinding()]
	param
	(	
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Default","Enabled","Disabled")]
        [String]$SixToFour,
        
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Automatic","Client","Default","Disabled","Enterpriseclient","Server")]
        [String]$Teredo,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Default","Enabled","Disabled")]
        [String]$ISATAP
	)

    if ($SixToFour)
    { 
        Write-Verbose 'Setting 6to4'
        Set-Net6to4Configuration -State $SixToFour
    }

    if ($Teredo)
    {
        Write-Verbose 'Setting Teredo'
        Set-NetTeredoConfiguration -Type $Teredo
    }
    
    if ($ISATAP)
    {
        Write-Verbose "Setting ISATAP to $ISATAP.."
        Set-NetIsatapConfiguration -State $ISATAP -PassThru
        Write-Verbose "Setting ISATAP ResolutionState to $ISATAP.."
        Set-NetIsatapConfiguration -ResolutionState $ISATAP -PassThru
    }
} #Set-TargetResource
        

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
	param
	(		
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Default","Enabled","Disabled")]
        [String]$SixToFour,
        
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Automatic","Client","Default","Disabled","Enterpriseclient","Server")]
        [String]$Teredo,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Default","Enabled","Disabled")]
        [String]$ISATAP
	)

    $result = @()

    if ($SixToFour)
    { 
        $result += ($SixToFour -eq (Get-Net6to4Configuration).State)
    }
    if ($Teredo)
    {
        $result += ($Teredo -eq (Get-NetTeredoConfiguration).Type)
    }
    if ($ISATAP)
    { 
        $result += ($ISATAP -eq (Get-NetIsatapConfiguration).State -and 
                    $ISATAP -eq (Get-NetIsatapConfiguration).ResolutionState)
    }

    Write-Verbose "Results are in (SixToFour/Teredo/ISATAP): $result"
    $bool = $True
    $result.ForEach({ if ($_ -eq $False) { $bool = $False } })
    return $bool
} #Test-TargetResource

Export-ModuleMember -function *-TargetResource