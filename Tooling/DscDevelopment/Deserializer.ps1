#
# Functions for examining DSC MOF documents. #
# Because parsing and validation require that the classes
# are available when loading an instance document, we maintain and in-memory cache of the classes
# that are loaded. The typical use pattern looks something like:
#
#   Reset-CimClassCache   # Clears the cache, then loads the system default DSC classes
#
#   Add-CachedCimClass -MofClassFile myClasses.mof        # add classes defined in the file to the cache
#   Add-CachedCimClass -MofClassFile moreOfMyClasses.mof  # add classes defined in a second file
#
#   Get-CachedCimClass -ListLoadedFiles                   # List all of the loaded files
#   Get-CachedCimClass -FileName (rvpa myClasses.mof)     # List all of the classes defined in specifed file.
#
#   Import-CimInstances -MofInstanceFilePath myInstances.mof # import and emit all CIM instances defined in this doc.
#
 
<#
.Synopsis
   Reset the CIM class cache
.DESCRIPTION
   Before a MOF file defining CIM instances can be read, the classes
   must be loaded into the class cache. Calling this cmdlet resets the
   class cache to the default classes
.EXAMPLE
   Reset-CimClassCache
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Reset-CimClassCache
{
    [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ClearCache()
    [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::LoadDefaultCimKeywords()
}
 
<#
.Synopsis
   Adds the classes defined in a MOF file to the current set of classes
.DESCRIPTION
   Before a MOF file defining CIM instances can be read, the classes
   must be loaded into the class cache. Calling this function will import classes
   from a MOF file and add them to the set of cached classes. It must be used
   to import the CIM class definition of any custom classes that might be
   contained in an instance document.
.EXAMPLE
   Add-CachedCimClass ./mtFileDefininingCustomCimClasses.schema.mof
#>
function Add-CachedCimClass
{
    [CmdletBinding(DefaultParameterSetName="FromMofFile")]
    param (
        # The MOF file to import classes from
        [Parameter(ParameterSetName="FromMofFile", ValueFromPipelineByPropertyName, Position=0)]
        [alias('fullname', 'path')]
        [string]
            $MofClassFile,
        [Parameter(ParameterSetName="FromModule")]
            $Module
    )
 
    process {
      $errors = New-Object System.Collections.ObjectModel.Collection[Exception]
   
      try
      {
          if ($PSCmdlet.ParameterSetName -eq "FromMofFile")
          {
          $resolvedMofPath = Resolve-Path -ErrorAction stop $MofClassFile
          [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportClasses($resolvedMofPath, $null, $errors)
          $errors | Write-Error
          }
          else
          {
              foreach ($mi in Get-Module -ListAvailable -Name $Module)
              {
                  Write-Verbose -Verbose:$Verbose "Processing module $($module.Name)"
                  $schemaFile = ""
                  [void] [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportCimKeywordsFromModule($mi, $null, [ref] $schemaFile)
                  if ($schemaFile)
                  {
                      Write-Verbose -Verbose:$verbose "  Schema loaded from file: '$schemaFile'"
                  }
                  else
                  {
                      Write-Verbose -Verbose:$verbose "  No schema file was found."
                  }
              }
          }
      }
      catch
      {
          throw $_
      }
  }
}
 
<#
.Synopsis
   Returns Dump out all of the cached CIM classes
.DESCRIPTION
   Before a MOF file defining CIM instances can be read, the classes
   must be loaded into the class cache or an error will occur, This function will
.EXAMPLE
   Import-CimInstances ./myInstanceDoc.mof
#>
 
function Get-CachedCimClass
{
    [CmdletBinding(DefaultParameterSetName="ByClassName")]
    param (
        [Parameter(ParameterSetName="ByClassName", Position=0)]
        $ClassName = "*",
        [Parameter(ParameterSetName="ByFileName")]
            $FileName,
        [Parameter(ParameterSetName="ByModuleName")]
            $ModuleName,
        [Parameter(ParameterSetName="ListLoadedFiles")]
        [switch]
            $ListLoadedFiles
    )
 
    switch ($PSCmdlet.ParameterSetName)
    {
        ByFileName {
            [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::GetCachedClassByFileName($FileName)
            break
        }
        ByModuleName {
            [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::GetCachedClassByModuleName($ModuleName)
            break
        }
        ListLoadedFiles {
            [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::GetLoadedFiles()
            break
        }
        default {
            [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::GetCachedClasses().
                Where{$_.CimClassName -like $ClassName}
            break
        }
    }
}
 
<#
.Synopsis
   Returns CIM instances defined in a MOF file.
.DESCRIPTION
   This file will parse a MOF instance document and return the resulting instances.
   But before a MOF file defining CIM instances can be read, the classes
   must be loaded into the class cache or an error will occur
.EXAMPLE
   Import-CimInstance ./myInstanceDoc.mof
#>
function Import-CimInstance
{
    param (
        [parameter(ValueFromPipelineByPropertyName)]
        [alias('fullname', 'path')]
        [string]
        $MofInstanceFilePath
    )
 
    process {
      try
      {
          
          $resolvedMofPath = Resolve-Path -ErrorAction stop $MofInstanceFilePath
          [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportInstances($resolvedMofPath)
      }
      catch
      {
          Write-Error -Exception $_.Exception -Message "Error with $MofInstanceFilePath"
      }
    }
}

