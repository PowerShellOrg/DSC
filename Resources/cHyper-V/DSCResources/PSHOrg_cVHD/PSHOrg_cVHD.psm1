function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
    param
    (
	    [parameter(Mandatory)]
	    [String]$Name,

	    [parameter(Mandatory)]
	    [String]$Path,

	    # Virtual disk format - Vhd or Vhdx
        [ValidateSet("Vhd","Vhdx")]
	    [String]$Generation = "Vhd"
    )
    
    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw "Please ensure that Hyper-V role is installed with its PowerShell module"
    }
   
    # Construct the full path for the vhdFile
    $vhdName = GetNameWithExtension -Name $Name -Generation $Generation
    $vhdFilePath = Join-Path -Path $Path -ChildPath $vhdName
    Write-Debug -Message "Vhd full path is $vhdFilePath"

    $vhd = Get-VHD -Path $vhdFilePath -ErrorAction SilentlyContinue
    @{
	    Name             = $Name
	    Path             = $Path
	    ParentPath       = $vhd.ParentPath
	    Generation       = $vhd.VhdFormat
	    Ensure           = if($vhd){"Present"}else{"Absent"}
	    ID               = $vhd.DiskIdentifier
	    Type             = $vhd.VhdType
        FileSizeBytes    = $vhd.FileSize
        MaximumSizeBytes = $vhd.Size
        IsAttached       = $vhd.Attached
    }
}

function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		# Name of the VHD File
        [parameter(Mandatory)]
		[String]$Name,

		# Folder where the VHD will be created
        [parameter(Mandatory)]
		[String]$Path,

        # Parent VHD file path, for differencing disk
        [String]$ParentPath,

        # Size of Vhd to be created
        [Uint64]$MaximumSizeBytes,

		# Virtual disk format - Vhd or Vhdx
        [ValidateSet("Vhd","Vhdx")]
        [String]$Generation = "Vhd",

		# Should the VHD be created or deleted
        [ValidateSet("Present","Absent")]
		[String]$Ensure = "Present"
	)
    
    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw "Please ensure that Hyper-V role is installed with its PowerShell module"
    }

    # Construct the full path for the vhdFile
    $vhdName = GetNameWithExtension -Name $Name -Generation $Generation
    $vhdFilePath = Join-Path -Path $Path -ChildPath $vhdName
    Write-Debug -Message "Vhd full path is $vhdFilePath"

    Write-Verbose -Message "Checking if $vhdFilePath is $Ensure ..."

    # If vhd should be absent, delete it
    if($Ensure -eq "Absent")
    {
        if (Test-Path $vhdFilePath)
        {
            Write-Verbose -Message "$vhdFilePath is not $Ensure"
            Remove-Item -Path $vhdFilePath -Force -ErrorAction Stop             
        }
	    Write-Verbose -Message "$vhdFilePath is $Ensure"
    }  

    else
    {
        # Check if the Vhd is present
        try
        {
            	$vhd = Get-VHD -Path $vhdFilePath -ErrorAction Stop

                # If this is a differencing disk, check the parent path
                if($ParentPath)
                {
                    Write-Verbose -Message "Checking if $vhdFilePath parent path is $ParentPath ..."
        
                    # If the parent path is not set correct, fix it
                    if($vhd.ParentPath -ne $ParentPath)
                    {
                        Write-Verbose -Message "$vhdFilePath parent path is not $ParentPath."
                        Set-VHD -Path $vhdFilePath -ParentPath $ParentPath
                        Write-Verbose -Message "$vhdFilePath parent path is now $ParentPath."
                    }
                    else
                    {
                        Write-Verbose -Message "$vhdFilePath is $Ensure and parent path is set to $ParentPath."                
                    }
                }

                # This is a fixed disk, check the size
                else
                {
                    Write-Verbose -Message "Checking if $vhdFilePath size is $MaximumSizeBytes ..."

                    # If the size is not correct, fix it
                    if($vhd.Size -ne $MaximumSizeBytes)
                    {
                        Write-Verbose -Message "$vhdFilePath size is not $MaximumSizeBytes."
                        Resize-VHD -Path $vhdFilePath -SizeBytes $MaximumSizeBytes
                        Write-Verbose -Message "$vhdFilePath size is now $MaximumSizeBytes."
                    }
                    else
                    {
                        Write-Verbose -Message "$vhdFilePath is $Ensure and size is $MaximumSizeBytes."                
                    }
                }
        }    

    # Vhd file is not present
    catch [System.Management.Automation.ActionPreferenceStopException]
    {
      
            Write-Verbose -Message "$vhdFilePath is not $Ensure"
            if($ParentPath)
            {
                $null = New-VHD -Path $vhdFilePath -ParentPath $ParentPath
            }
            else
            {
                $null = New-VHD -Path $vhdFilePath -SizeBytes $MaximumSizeBytes
            }
            Write-Verbose -Message "$vhdFilePath is now $Ensure"
    }

 }
    
}

function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		# Name of the VHD File
        [parameter(Mandatory)]
		[String]$Name,

		# Folder where the VHD will be created
        [parameter(Mandatory)]
		[String]$Path,

		# Parent VHD file path, for differencing disk
        [String]$ParentPath,

        # Size of Vhd to be created
        [Uint64]$MaximumSizeBytes,

		# Virtual disk format - Vhd or Vhdx
        [ValidateSet("Vhd","Vhdx")]
		[String]$Generation = "Vhd",

		# Should the VHD be created or deleted
        [ValidateSet("Present","Absent")]
		[String]$Ensure = "Present"
	)

    #region input validation
    
    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw "Please ensure that Hyper-V role is installed with its PowerShell module"
    }

    if(! ($ParentPath -or $MaximumSizeBytes))
    {
       Throw "Either specify ParentPath or MaximumSize property." 
    }
            
    if($ParentPath)
    {
        # Ensure only one value is specified - differencing disk or new disk
        if($MaximumSizeBytes)
        {
            Throw "Cannot specify both ParentPath and MaximumSize. Specify only one and try again."
        }
        
        if(! (Test-Path -Path $ParentPath))
        {
            Throw "$ParentPath does not exists"
        }
            
        # Check if the generation matches parenting disk
        if($Generation -and ($ParentPath.Split('.')[-1] -ne $Generation))
        {
            Throw "Generation $geneartion should match ParentPath extension $($ParentPath.Split('.')[-1])"
        }
    }
    if(!(Test-Path -Path $Path))
    {
        Throw "$Path does not exists"
    }

    # Construct the full path for the vhdFile
    $vhdName = GetNameWithExtension -Name $Name -Generation $Generation
    $vhdFilePath = Join-Path -Path $Path -ChildPath $vhdName
    Write-Debug -Message "Vhd full path is $vhdFilePath"

	# Add the logic here and at the end return either $true or $false.
    $result = Test-VHD -Path $vhdFilePath -ErrorAction SilentlyContinue
    Write-Verbose -Message "Vhd $vhdFilePath is present:$result and Ensure is $Ensure"
    return ($result -and ($Ensure -eq "Present"))
}

# Appends the generation to the name provided if it is not part of the name already.
function GetNameWithExtension
{
    param(
    # Name of the VHD File
        [parameter(Mandatory)]
		[String]$Name,
        [parameter(Mandatory)]
		[String]$Generation ='Vhd'
      )

     # If the name ends with vhd or vhdx don't append the generation to the vhdname.
    if ($Name -like '*.vhd' -or $Name -like '*.vhdx')
    {
        $extension = $Name.Split('.')[-1]
        if ($Generation -ne $extension)
        {
            throw "the extension $extension on the name does match the generation $Generation"
        }
        else
        {                
            Write-Debug -Message "Vhd full name is $vhdName"
            $vhdName = $Name
        }
    }
    else
    {
        # Append generation to the name
        $vhdName = "$Name.$Generation"
        Write-Debug -Message "Vhd full name is $vhdName"
    }

    return $vhdName
}

Export-ModuleMember -Function *-TargetResource

