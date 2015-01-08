function New-DscNodeMetadata
{
    <#
        .Synopsis
            Creates a new Dsc metadata file describing a node.
        .Description
            Create a new Dsc metadata file to populate AllNodes in a Dsc Configuration.
        .Example
            New-DscNodeMetadata -Name NY-TestSQL01 -Location NY -ServerType VM
        .Example
            New-DscNodeMetadata -Name NY-TestService01 -Location NY -ServerType Physical
    #>
    param
    (
        #Server name, same as ActiveDirectory server account name.
        [parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1
        )]
        [string]
        $Name,

        #Data center or site the server is in.
        [parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 2
        )]
        [string]
        $Location,

        #Unique identifier for this node.  Will automatically generate one if not supplied.
        [parameter(
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [guid]
        $NodeName,

        #Path to the AllNodes subfolder in the configuration data folder.
        #Defaults to ${repository root}/Configuration/AllNodes
        [parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Services = @()
    )
    begin
    {
        if ($psboundparameters.containskey('path')) {
                    $psboundparameters.Remove('path') | out-null
        }
        Resolve-ConfigurationDataPath -Path $Path

        $AllNodesConfigurationPath = (join-path $script:ConfigurationDataPath 'AllNodes')
    }
    process
    {
        if (-not $psboundparameters.containskey('NodeName')){
            $psboundparameters.Add('NodeName', [guid]::NewGuid().Guid)
        }
        Out-ConfigurationDataFile -Parameters $psboundparameters -ConfigurationDataPath $AllNodesConfigurationPath
    }

}

function New-DscServiceMetadata {
    [cmdletbinding()]
    param (
        [parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]
        $Name,
        [string[]]
        $Nodes,
        [string]
        $Path
    )

    begin {
        if ($psboundparameters.containskey('path')) {
                    $psboundparameters.Remove('path') | out-null
        }
        Resolve-ConfigurationDataPath -Path $Path

        $ServicesConfigurationPath = (join-path $script:ConfigurationDataPath 'Services')
    }
    process {
        $OutConfigurationDataFileParams = @{
            Parameters = $psboundparameters
            ConfigurationDataPath = $ServicesConfigurationPath
            DoNotIncludeName = $true
        }
        Out-ConfigurationDataFile @OutConfigurationDataFileParams
    }
}

function New-DscSiteMetadata {
    [cmdletbinding()]
    param (
        [string]
        $Name,
        [string]
        $Path
    )

    begin {
        if ($psboundparameters.containskey('path')) {
                    $psboundparameters.Remove('path') | out-null
        }
        Resolve-ConfigurationDataPath -Path $Path

        $SiteDataConfigurationPath = (join-path $script:ConfigurationDataPath 'SiteData')
    }
    process {
        Out-ConfigurationDataFile -Parameters $psboundparameters -ConfigurationDataPath $SiteDataConfigurationPath
    }
}


function Out-ConfigurationDataFile {
    [cmdletbinding()]
    param($Parameters, $ConfigurationDataPath, [switch]$DoNotIncludeName)

    $StartingBlock = "@{"
    $EndingBlock = "}"
    $ExcludedParameters = [System.Management.Automation.Internal.CommonParameters].GetProperties().Name
    if ($DoNotIncludeName) {
        $ExcludedParameters += 'Name'
    }
    $ofs = "', '"

    $configuration = @(
        $StartingBlock
        foreach ($key in $Parameters.keys) {
            if ($ExcludedParameters -notcontains $key )
            {
                "    $key = '$($Parameters[$key])'"
            }
        }
        $EndingBlock
    )

    $configuration | Out-File (Join-Path $ConfigurationDataPath "$($Parameters['Name']).psd1") -Encoding Ascii
}


