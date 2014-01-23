function Get-DscEventLog
{
    param ($Session)

    icm $Session -script {
        get-winevent -LogName Microsoft-Windows-DSC/Operational -force -Oldest | 
            sort TimeCreated -desc 
    } | 
        select logname, TimeCreated, Message 
}
