# A simple configuration to join a workgroup computer to a domain

Configuration Sample_cComputer_WorkgroupToDomain
{
    param
    (
        [string[]]$NodeName="localhost",

        [Parameter(Mandatory)]
        [string]$MachineName,

        [Parameter(Mandatory)]
        [string]$Domain,

        [Parameter(Mandatory)]
        [pscredential]$Credential
    )

    #Import the required DSC Resources
    Import-DscResource -Module cComputerManagement

    Node $NodeName
    {
        cComputer JoinDomain
        {
            Name          = $MachineName 
            DomainName    = $Domain
            Credential    = $Credential  # Credential to join to domain
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

Sample_cComputer_WorkgroupToDomain -ConfigurationData $ConfigData -MachineName <machineName> -credential (Get-Credential) -Domain <domainName>
****************************#>
