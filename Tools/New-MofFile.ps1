function New-MofFile
{
    <#
    .Synopsis
       Generates a MOF Class declaration for a DSC Module
    .DESCRIPTION
       Uses the parameters of Set-TargetResource in a DSC Resource Module to generate a MOF schema file for use in DSC.
    .EXAMPLE
       New-MofFile -Name Pagefile
    #>
    param (
        $ModuleName,
        $Name,        
        $Version = '1.0.0'
    )

    $module = Import-Module $ModuleName -PassThru
    $ModuleName = $Module.Name    
    
    if ([string]::IsNullOrEmpty($Name))
    {
        $Name = $module.Name
    }

    #Switch MSFT_BaseResourceConfiguration to OMI_BaseResource for WMF4 and RTM
    $Template = @"
[version("$Version"), FriendlyName("$Name")]
class $ModuleName :  MSFT_BaseResourceConfiguration
{

"@
    $CommonParameters = 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 
                        'WarningVariable', 'ErrorVariable', 'OutVariable', 
                        'OutBuffer', 'PipelineVariable', 'Confirm', 'Whatif'

    $Command = get-command -Name Set-TargetResource -Module $ModuleName | select -First 1

    foreach ($key in $Command.Parameters.Keys)
    {
        
        if ($CommonParameters -notcontains $key)
        {
            $CurrentParameter = $Command.Parameters[$key]
            $IsKey = $false
            $PropertyString = "`t"
            
            $ParameterAttribute = $CurrentParameter.Attributes | 
                Where-Object {$_ -is [System.Management.Automation.ParameterAttribute]}
            $ValidateSetAttribute = $CurrentParameter.Attributes | 
                Where-Object {$_ -is [System.Management.Automation.ValidateSetAttribute]}

            if ($ParameterAttribute.Mandatory -and
                (-not $CurrentParameter.ParameterType.IsArray) )
            {
                $PropertyString += '[Key'
                $IsKey = $true
            }
            else
            {
                $PropertyString += '[write'
                
            }

            if ($ValidateSetAttribute -ne $null)
            {
                $OFS = '", "'
                $PropertyString += ',ValueMap{"' + "$($ValidateSetAttribute.ValidValues)"
                $PropertyString += '"},Values{"' + "$($ValidateSetAttribute.ValidValues)"
                $PropertyString += '"}'
            }        
            
            switch ($CurrentParameter.ParameterType)
            {
                {$_ -eq [System.String]} { $PropertyString += '] string ' + "$key;`n" }
                {$_ -eq [System.Management.Automation.SwitchParameter]} { $PropertyString += '] boolean ' + "$key;`n"}
                {$_ -eq [System.Management.Automation.PSCredential]} { $PropertyString += ',EmbeddedInstance("MSFT_Credential")] string ' + "$key;`n"}
                {$_ -eq [System.String[]]} { $PropertyString += '] string ' + "$key[];`n" }
                {$_ -eq [System.Int64]} { $PropertyString += '] sint64 ' + "$key;`n" }
                {$_ -eq [System.Int64[]]} { $PropertyString += '] sint64 ' + "$key[];`n" }
                {$_ -eq [System.Int32]} { $PropertyString += '] sint32 ' + "$key;`n" }
                {$_ -eq [System.Int32[]]} { $PropertyString += '] sint32 ' + "$key[];`n" }

                default { Write-Warning "Don't know what to do with $_";}
            }
            
            $Template += $PropertyString
        }
        
    }
    $Template += @'
};
'@
    
    $TargetPath = join-path $Module.ModuleBase "$ModuleName.schema.mof"
    
    if (Test-Path $TargetPath)
    {
        Write-Verbose "Removing previous file from $TargetPath."
        Remove-Item -Path $TargetPath -Force
    }

    Write-Verbose "Writing $ModuleName.schema.mof to $TargetPath"

    $Template | 
        Out-File -Encoding ascii -FilePath $TargetPath

}