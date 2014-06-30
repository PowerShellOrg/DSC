# A configuration to change the machine name within the same workgroup
 
configuration Sample_cComputer_ChangeNameInWorkgroup
{
    param
    (
        [string[]]$NodeName="localhost",

        [Parameter(Mandatory)]
        [string]$MachineName
    )

    #Import the required DSC Resources     
    Import-DscResource -Module cComputerManagement

    Node $NodeName
    {
        cComputer NewName
        {
            Name = $MachineName
        }
    }
}
