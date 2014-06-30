# A configuration to move a machine from a Domain to a WorkGroup -- note: a credential is required

Configuration Sample_cComputer_DomainToWorkgroup
{
    param
    (
        [string[]]$NodeName="localhost",

        [Parameter(Mandatory)]
        [string]$MachineName,

        [Parameter(Mandatory)]
        [string]$WorkGroup,

        [Parameter(Mandatory)]
        [pscredential]$Credential
    )

    #Import the required DSC Resources     
    Import-DscResource -Module cComputerManagement

    Node $NodeName
    {
        cComputer JoinWorkgroup
        {
            Name          = $MachineName
            WorkGroupName = $WorkGroup
            Credential    = $Credential # Credential to unjoin from domain
        }
    }
}

<#****************************
To save the credential in plain-text in the mof file, use the following configuration data

$ConfigData = @{  
                AllNodes = @(       
                                @{    
                                    NodeName = "localhost";

                                    # Allows credential to be saved in plain-text in the the *.mof instance document.                            
                                    PSDscAllowPlainTextPassword = $true;
                                };                                                                                       
                            );      
            }    

Sample_cComputer_DomainToWorkgroup -ConfigurationData $ConfigData -MachineName <machineName> -credential (Get-Credential) -WorkGroup <workgroupName>
****************************#>

