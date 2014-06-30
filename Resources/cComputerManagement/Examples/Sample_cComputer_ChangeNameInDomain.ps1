# A configuration to change machine while in the same domain
 
Configuration Sample_cComputer_ChangeNameInDomain
{
    param
    (
        [string[]]$NodeName="localhost",

        [Parameter(Mandatory)]
        [string]$MachineName,

        [Parameter(Mandatory)]
        [pscredential]$Credential
    )

    #Import the required DSC Resources 
    Import-DscResource -Module cComputerManagement

    Node $NodeName
    {
        cComputer NewName
        {
            Name          = $MachineName
            Credential    = $Credential # Domain credential
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

Sample_xComputer_ChangeNameInDomain -ConfigurationData $ConfigData -MachineName <machineName>  -Credential (Get-Credential)

*****************************#>
