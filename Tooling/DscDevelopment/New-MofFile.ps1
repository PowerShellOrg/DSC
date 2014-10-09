function New-MofFile
{
    <#
    .Synopsis
       Generates a MOF Class declaration for a DSC Resource
    .DESCRIPTION
       Uses the parameters of Set-TargetResource in a DSC Resource Module to generate a MOF schema file for use in DSC.
    .EXAMPLE
       New-MofFile -Name d:\source\dsc-prod\resources\baseresources\dscresources\Pagefile
    #>
    param (
        [parameter()]
        [string]
        $Path,        
        $Version = '1.0' ,
    
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $FriendlyName ,

        [Switch]
        $LoadTypes
)
  
    $ResourceName = Split-Path $Path -Leaf
   
    if (!$FriendlyName) {
        $FriendlyName = $ResourceName
    }

    $ResourcePath = Join-Path $Path "$ResourceName.psm1"

    Write-Verbose "Attempting to parse $ResourcePath."
    try
    {
        $CommandAst = [System.Management.Automation.Language.Parser]::ParseFile($ResourcePath, [ref]$null, [ref]$null)
        $SetTargetResourceAst = $CommandAst.FindAll(
            {$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]},
            $false
        ) | 
            Where-Object {$_.name -like 'Set-TargetResource'}

        $ParametersAst = $SetTargetResourceAst.Body.ParamBlock.Parameters
           
        # Look for type definitions and execute them in this context
        # This could be very buggy.
        if ($LoadTypes) {
            Write-Warning "Types added to session with -LoadType will remain in the session until it ends."
            $CommandAst.FindAll(
                {$args[0] -is [System.Management.Automation.Language.CommandAst]},
                $false
            ) |
                Where-Object { $_.CommandElements[0].Value -ieq 'Add-Type' } |
                ForEach-Object {
                    Write-Verbose "Adding type:`n`n$($_.ToString())"
                    Invoke-Expression $_.ToString() -ErrorAction Continue
                }
        }

        $Template = @"
[ClassVersion("$Version"), FriendlyName("$FriendlyName")]
class $ResourceName : OMI_BaseResource
{

"@
        foreach ($ParameterAst in $ParametersAst)
        {
            $PropertyString = '[write'
            $IsKey = $false

            $ParameterName = $ParameterAst.Name -replace '\$'
            Write-Verbose "Processing $ParameterName."

            $ParameterAttributesAst = $ParameterAst.Attributes | 
                Where-Object {$_ -is [System.Management.Automation.Language.AttributeAst]}                           
            $ParameterTypeAttributeAst = $ParameterAst.Attributes | 
                Where-Object {$_ -is [System.Management.Automation.Language.TypeConstraintAst]}
                
            switch ($ParameterAttributesAst)
            {
                {($_.typename -like 'parameter') -and (($_.NamedArguments.ArgumentName) -contains 'Mandatory')} {
                                Write-Verbose "Parameter - $ParameterName is Mandatory."
                                $PropertyString = '[Key'
                                $IsKey = $true
                            }
            }

            switch ($ParameterAttributesAst)
            {
                {$_.typename -like 'ValidateSet'} {
                                Write-Verbose "Parameter - $ParameterName has a validate set."
                                $oldOFS = $OFS
                                $OFS = '", "'
                                $SingleQuote = "'"
                                $ValidValues = "$($_.PositionalArguments.Value -replace $SingleQuote)"
                                $PropertyString += @"
,ValueMap{"$ValidValues"},Values{"$ValidValues"}
"@
                                $OFS = $oldOFS
                            }
            }
                       
            Write-Verbose "Parameter - $ParameterName is typed with $($ParameterTypeAttributeAst.TypeName)."

            $type = $ParameterTypeAttributeAst.TypeName.FullName -as [Type]

            $table = @{
                [string]       = 'string'
                [string[]]     = 'string'
                [switch]       = 'boolean'
                [bool]         = 'boolean'
                [boolean[]]    = 'boolean'
                [long]         = 'sint64'
                [long[]]       = 'sint64'
                [int]          = 'sint32'
                [int[]]        = 'sint32'
                [byte]         = 'uint8'
                [byte[]]       = 'uint8'
                [uint32]       = 'uint32'
                [uint32[]]     = 'uint32'
                [uint64]       = 'uint64'
                [uint64[]]     = 'uint64'
            }

            if ($table.ContainsKey($type))
            {
                $PropertyString += "] $($table[$type]) "
            }
            elseif ($type -eq [pscredential])
            {
                $PropertyString += ',EmbeddedInstance("MSFT_Credential")] string '
            }
            else
            {
                $goodType = $false

                if ($null -ne $type -and $type.IsEnum)
                {
                    Write-Verbose "'$type' is an Enum type. Let's convert it into a ValueMap."

                    $eNames = ($type.GetEnumNames() | ForEach-Object { "`"$_`"" }) -join ','
                    $eValues = ($type.GetEnumValues().value__ | ForEach-Object { "`"$_`"" }) -join ','
                    $eType = $type.GetEnumUnderlyingType()

                    if ($table.ContainsKey($eType))
                    {
                        $goodType = $true
                        $PropertyString += ",ValueMap{$eValues},Values{$eNames}] $($table[$eType]) "
                    }
                }
                
                if (-not $goodType)
                {
                    Write-Warning "Don't know what to do with $($ParameterTypeAttributeAst.TypeName.FullName)"
                }
            }

            $arrayString = if ($type.IsArray) { '[]' } else { '' }

            $Template += $PropertyString + "$ParameterName$arrayString;`r`n"
        }

        $Template += @'
};
'@
    
        $TargetPath = join-path $Path "$ResourceName.schema.mof"
    
        if (Test-Path $TargetPath)
        {
            Write-Verbose "Removing previous file from $TargetPath."
            Remove-Item -Path $TargetPath -Force
        }

        Write-Verbose "Writing $ResourceName.schema.mof to $Path"

        $Template | 
            Out-File -Encoding ascii -FilePath $TargetPath
    }
    catch
    {
        throw $_
    }
}


