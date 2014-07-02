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
        $Version = '1.0'
    )
  
    $ResourceName = Split-Path $Path -Leaf
   
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
           
        $Template = @"
[ClassVersion("$Version"), FriendlyName("$ResourceName")]
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
                                $OFS = '", "'
                                $SingleQuote = "'"
                                $ValidValues = "$($_.PositionalArguments -replace $SingleQuote)"
                                $PropertyString += @"
,ValueMap{"$ValidValues"},Values{"$ValidValues"}
"@
                            }
            }
                        

            
            $IsArray = $false
            Write-Verbose "Parameter - $ParameterName is typed with $($ParameterTypeAttributeAst.TypeName)."
            switch ($ParameterTypeAttributeAst.TypeName)
            {
                {$_ -like 'string'} { $PropertyString += '] string ' }
                {$_ -like 'switch'} { $PropertyString += '] boolean '}
                {$_ -like 'bool'} { $PropertyString += '] boolean '}
                {$_ -like 'System.Management.Automation.PSCredential'} { $PropertyString += ',EmbeddedInstance("MSFT_Credential")] string '}
                {$_ -like 'string`[`]'} { $PropertyString += '] string '; $IsArray = $true}
                {$_ -like 'long'} { $PropertyString += '] sint64 '}
                {$_ -like 'long`[`]'} { $PropertyString += '] sint64 '; $IsArray = $true}
                {$_ -like 'int'} { $PropertyString += '] sint32 '}
                {$_ -like 'int`[`]'} { $PropertyString += '] sint32 '; $IsArray = $true}

                default { Write-Warning "Don't know what to do with $_";}
            }
            if ($IsArray)
            {
                $ParameterName = "$ParameterName[]"
            }
                
            $Template += $PropertyString + "$ParameterName;`r`n"                 
            
        
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


