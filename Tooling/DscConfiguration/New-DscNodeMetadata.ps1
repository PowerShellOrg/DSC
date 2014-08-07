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
            Position = 1
        )]              
        [string]
        $Location,       

        #Type of server (physical or virtual)
        [parameter(
            Mandatory,
            ValueFromPipelineByPropertyName        
        )]      
        [ValidateSet('Physical','VM')]  
        [string]
        $ServerType,  


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
        $Path
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
        [string[]]
        $Roles,
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

    $StartingBlock = "@{`r`n"
    $EndingBlock = "`r`n}"
    $ExcludedParameters = [System.Management.Automation.Internal.CommonParameters].GetProperties().Name    
    if ($DoNotIncludeName) {
        $ExcludedParameters += 'Name'
    }
    $ofs = "', '"

    $configuration = $StartingBlock
    foreach ($key in $Parameters.keys) {
        if ($ExcludedParameters -notcontains $key )
        {
            $Configuration += "`r`n`t$key = '$($Parameters[$key])'"
        }
    }
    
    $Configuration += $EndingBlock
    
    $configuration | out-file (join-path $ConfigurationDataPath "$($Parameters['Name'].toupper()).psd1") -Encoding Ascii

}

