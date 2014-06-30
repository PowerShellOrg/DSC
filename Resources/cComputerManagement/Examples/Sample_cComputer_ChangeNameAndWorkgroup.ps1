# A configuration to change the machine workgroup and its name 
 
Configuration Sample_cComputer_ChangeNameAndWorkGroup
{
    param
    (
        [string[]]$NodeName="localhost",

        [Parameter(Mandatory)]
        [string]$MachineName,
        
        [Parameter(Mandatory)]
        [string]$WorkGroupName
    )
     
    #Import the required DSC Resources 
    Import-DscResource -Module cComputerManagement

    Node $NodeName
    {
        cComputer NewNameAndWorkgroup
        {
            Name          = $MachineName
            WorkGroupName = $WorkGroupName
        }
    }
}
