
<#
#  Get the current configuration of the machine 
#  This function is called when you do Get-DscConfiguration after the configuration is set.
#>
function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$VhdPath,

		[parameter(Mandatory = $true)]
		[Microsoft.Management.Infrastructure.CimInstance[]]
		$FileDirectory
	)

    if ( -not (Test-path $VhdPath))
    {
        $item = New-CimInstance -ClassName MSFT_FileDirectoryConfiguration -Property @{DestinationPath = $VhdPath; Ensure = "Absent"} -Namespace root/microsoft/windows/desiredstateconfiguration -ClientOnly
            
        Return @{
            VhdPath = $VhdPath
            FileDirectory = $item
         }
    }

    # Mount VHD.
    $mountVHD = EnsureVHDState -Mounted -vhdPath $vhdPath
    
    $itemsFound = foreach($Item in $FileDirectory)
    {
        $item = GetItemToCopy -item $item
        $mountedDrive =  $mountVHD | Get-Disk | Get-Partition | Get-Volume
        $letterDrive  = "$($mountedDrive.DriveLetter):\" 
       
        # show the drive letters.
        Get-PSDrive | Write-Verbose       

        $finalPath = Join-Path $letterDrive $item.DestinationPath
        
        Write-Verbose "Getting the current value at $finalPath ..."

        if (Test-Path $finalPath)
        {
            New-CimInstance -ClassName MSFT_FileDirectoryConfiguration -Property @{DestinationPath = $finalPath; Ensure = "Present"} -Namespace root/microsoft/windows/desiredstateconfiguration -ClientOnly
        }
        else
        {            
            New-CimInstance -ClassName MSFT_FileDirectoryConfiguration -Property @{DestinationPath = $finalPath ; Ensure = "Absent"} -Namespace root/microsoft/windows/desiredstateconfiguration -ClientOnly    
        }
   }

    # Dismount VHD.
    EnsureVHDState -Dismounted -vhdPath $VhdPath 
    
    # Return the result.
    Return @{
      VhdPath = $VhdPath
      FileDirectory = $itemsFound
    }   
}


# This is a resource method that gets called if the Test-TargetResource returns false.
function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$VhdPath,

		[parameter(Mandatory = $true)]
		[Microsoft.Management.Infrastructure.CimInstance[]]
		$FileDirectory
	)

    if (-not (Test-Path $VhdPath)) { throw "Specified destination path $VhdPath does not exist!"}   
    
    # mount the VHD.
    $mountedVHD = EnsureVHDState -Mounted -vhdPath $VhdPath

    try
    {
            # show the drive letters.
            Get-PSDrive | Write-Verbose

            $mountedDrive = $mountedVHD | Get-Disk | Get-Partition | Get-Volume
            
            foreach ($item in $FileDirectory)
            {
                $itemToCopy = GetItemToCopy -item $item
                $letterDrive = "$($mountedDrive.DriveLetter):\"
                $finalDestinationPath = $letterDrive
                $finalDestinationPath = Join-Path  $letterDrive  $itemToCopy.DestinationPath
               
                # if the destination should be removed 
                if (-not($itemToCopy.Ensure))
                {
                    if (Test-Path $finalDestinationPath)
                    {
                        SetVHDFile -destinationPath $finalDestinationPath -ensure:$false -recurse:($itemToCopy.Recurse)
                    }
                }
                else
                {
                    # Copy Scenario
                    if ($itemToCopy.SourcePath)
                    {
                        SetVHDFile -sourcePath $itemToCopy.SourcePath  -destinationPath $finalDestinationPath -recurse:($itemToCopy.Recurse) -force:($itemToCopy.Force)
                    }
                    elseif ($itemToCopy.Content)
                    {
                        "Writing a content to a file"

                        # if the type is not specified assume it is a file.
                        if (-not ($itemToCopy.Type))
                        {
                            $itemToCopy.Type = 'File'
                        }

                        # Create file/folder scenario
                        SetVHDFile -destinationPath $finalDestinationPath -type $itemToCopy.Type -force:($itemToCopy.Force)  -content $itemToCopy.Content
                    }                   

                    # Set Attribute scenario
                    if ($itemToCopy.Attributes)
                    {
                        SetVHDFile -destinationPath $finalDestinationPath -attribute $itemToCopy.Attributes -force:($itemToCopy.Force)
                    }
                }

            }
    }
    finally
    {
        EnsureVHDState -Dismounted -vhdPath $VhdPath
    }	
}

# This function returns if the current configuration of the machine is the same as the desired configration for this resource.
function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$VhdPath,

		[parameter(Mandatory = $true)]
		[Microsoft.Management.Infrastructure.CimInstance[]]
		$FileDirectory
	)

    # If the VHD path does not exist throw an error and stop.
    if ( -not (Test-Path $VhdPath))
    {
        throw "VHD does not exist in the specified path $VhdPath"
    } 

    # mount the vhd.
    $mountedVHD = EnsureVHDState -Mounted -vhdPath $VhdPath

    try 
    {
        # Show the drive letters after mount 
        Get-PSDrive | Write-Verbose

        $mountedDrive = $mountedVHD | Get-Disk | Get-Partition | Get-Volume
        $letterDrive  = "$($mountedDrive.DriveLetter):\"
        Write-Verbose $letterDrive

        # return test result equal to true unless one of the tests in the loop below fails.
        $result = $true

        foreach ($item in $FileDirectory)
        {  
            $itemToCopy = GetItemToCopy -item $item
            $destination =  $itemToCopy.DestinationPath  
            Write-Verbose ("Testing the file with relative VHD destination $destination")
            $destination =  $itemToCopy.DestinationPath
            $finalDestinationPath = $letterDrive
            $finalDestinationPath = Join-Path $letterDrive $destination
            if (Test-Path $finalDestinationPath) 
            {               
                  if( -not ($itemToCopy.Ensure))
                  {
                    $result = $false
                    break;
                  }
                  else
                  {
                        if (($itemToCopy.Type -eq "Directory") -and ($itemToCopy.Recurse))
                        {
                            # make sure the child also exists.                        
                            $allFilesToCopy = dir "$($itemToCopy.SourcePath)\*.*" -Recurse | % FullName | %{$_.Substring(($itemToCopy.SourcePath).Length)}
                            $allDestinationFiles = dir "$($itemToCopy.DestinationPath)\*.*" -Recurse | % FullName | %{$_.Substring(($itemToCopy.DestinationPath).Length)}
                            $allFilesToCopy | % { $result = $result -and $allDestinationFiles.Contains($_)}

                            if (-not ($result))
                            {
                                break;
                            }
                         }
                  }
            }
            else
            {
                # If Ensure is specified as Present or if Ensure is not specified at all.
                if(($itemToCopy.Ensure))
                {
                    $result = $false
                    break;
                }                
            }

            # Check the attribute 
            if ($itemToCopy.Attributes)
            {
                $currentAttribute = @(Get-ItemProperty -Path $finalDestinationPath |% Attributes)
                $result = $currentAttribute.Contains($itemToCopy.Attributes)
            }           
          }
    }
    finally
    {
        EnsureVHDState -Dismounted -vhdPath $VhdPath
    }
   
   return $result;
}

# Assert the state of the VHD.
function EnsureVHDState 
{
    [CmdletBinding(DefaultParametersetName="Mounted")] 
    param(        
        
        [parameter(Mandatory=$false,ParameterSetName = "Mounted")]
        [switch]$Mounted,
        [parameter(Mandatory=$false,ParameterSetName = "Dismounted")]  
        [switch]$Dismounted,
        [parameter(Mandatory=$true)]
        $vhdPath 
        )

        if ( -not ( Get-Module -ListAvailable Hyper-v))
        {
            throw "Hyper-v-Powershell Windows Feature is required to run this resource. Please install Hyper-v feature and try again"
        }
        if ($PSCmdlet.ParameterSetName -eq 'Mounted')
        {
             # Try mounting the VHD.
            $mountedVHD = Mount-VHD -Path $vhdPath -Passthru -ErrorAction SilentlyContinue -ErrorVariable var

            # If mounting the VHD failed. Dismount the VHD and mount it again.
            if ($var)
            {
                Write-Verbose "Mounting Failed. Attempting to dismount and mount it back"
                Dismount-VHD $vhdPath 
                $mountedVHD = Mount-VHD -Path $vhdPath -Passthru -ErrorAction SilentlyContinue

                return $mountedVHD            
            }
            else
            {
                return $mountedVHD
            }
        }
        else
        {
            Dismount-VHD $vhdPath -ea SilentlyContinue
                
        }
}

# Change the Cim Instance objects in to a hash table containing property value pair.
function GetItemToCopy
{
    param([Microsoft.Management.Infrastructure.CimInstance] $item)

    $returnValue =   @{
        SourcePath = $item.CimInstanceProperties["SourcePath"].Value
        DestinationPath = $item.CimInstanceProperties["DestinationPath"].Value 
        Ensure = $item.CimInstanceProperties["Ensure"].Value 
        Recurse = $item.CimInstanceProperties["Recurse"].Value
        Force = $item.CimInstanceProperties["Force"].Value  
        Content = $item.CimInstanceProperties["Content"].Value       
        Attributes = @($item.CimInstanceProperties["Attributes"].Value) 
        Type = $item.CimInstanceProperties["Type"].Value 
      }

      # Assign Default values, if they are not specified.
      if ($returnValue.Ensure -eq $null)
      {
        $returnValue.Ensure = "Present"
      }

      if ($returnValue.Force -eq $null)
      {
        $returnValue.Force = "True"
      }

      if ($returnValue.Recurse -eq $null)
      {
         $returnValue.Recurse  = "True"
      }

      # Convert string "True" or "False" to boolean for ease of programming.
      $returnValue.Force =  $returnValue.Force -eq "True"
      $returnValue.Recurse = $returnValue.Recurse -eq "True"
      $returnValue.Ensure = $returnValue.Ensure -eq "Present"
      $returnValue.Keys | %{ Write-Verbose "$_ => $($returnValue[$_])"}

    return $returnValue
}


# This is the main function that gets called after the file is mounted to perfom copy,set or new operations on the mounted drive.
function SetVHDFile
{
     [CmdletBinding(DefaultParametersetName="Copy")] 
    param(       
        [parameter(Mandatory=$true,ParameterSetName = "Copy")]
        $sourcePath,        
        [switch]$recurse,
        [switch]$force,
        [parameter(Mandatory=$false,ParameterSetName = "New")]  
        $type,
        [parameter(Mandatory=$false,ParameterSetName = "New")]  
        $content,       
        [parameter(Mandatory=$true)]
        $destinationPath, 
        [parameter(Mandatory=$true,ParameterSetName = "Set")]  
        $attribute,
        [parameter(Mandatory=$true,ParameterSetName = "Delete")]
        [switch]$ensure 
        )      
    
    Write-Verbose "Setting the VHD file $($PSCmdlet.ParameterSetName)"
    if ($PSCmdlet.ParameterSetName -eq 'Copy')
    {
        New-Item -Path (Split-Path $destinationPath) -ItemType Directory -ErrorAction SilentlyContinue
        Copy-Item -Path $sourcePath -Destination $destinationPath -Force:$force -Recurse:$recurse -ErrorAction SilentlyContinue
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'New')
    {
        If ($type -eq 'Direcotry')
        {
            New-Item -Path $destinationPath -ItemType $type
        }
        else
        {
            New-Item -Path $destinationPath -ItemType $type
            $content | Out-File $destinationPath 
        }

    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Set')
    {
        Write-Verbose "Attempting to change the attribute of the file $destinationPath to value $attribute"
        Set-ItemProperty -Path $destinationPath -Name Attributes -Value $attribute
    }
    elseif (!($ensure))
    {
        Remove-Item -Path $destinationPath -Force:$force -Recurse:$recurse
    }
}

Export-ModuleMember -Function *-TargetResource



