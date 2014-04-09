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
        [ValidateSet('NY','OR')]  
        [string]
        $Location,       

        #Type of server
        [parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1
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
        $ConfigurationPath = (join-path (split-path (split-path $psscriptroot)) Configuration/AllNodes)
        
    )
    begin
    {
        $StartingBlock = "@{`n"
        $EndingBlock = "`n}"
        $commonParameters = [System.Management.Automation.Internal.CommonParameters].GetProperties().Name
        $CommonParameters += 'NodeName'
        $ofs = "', '"
    }
    process
    {
        $configuration = $StartingBlock
        foreach ($key in $psboundparameters.keys) {
            if ($commonParameters -notcontains $key )
            {
                $Configuration += "`n$key = '$($psboundparameters[$key])'"
            }
        }
        
        if (-not $psboundparameters.containskey('NodeName')){
            $Configuration += "`nNodeName = '$([guid]::NewGuid().Guid)'"
        }
        
        $Configuration += $EndingBlock
        $configuration | out-file (join-path $ConfigurationPath "$($Name.toupper()).psd1") -Encoding Ascii
    }
    
}