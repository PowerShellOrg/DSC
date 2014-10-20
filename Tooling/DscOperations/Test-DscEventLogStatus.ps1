 function Test-DscEventLogStatus
 {
    param
    (
        [ValidateSet("Debug", "Analytic", "Operational")]
        $Channel = "Analytic"
    )

    return $(Get-WinEvent -ListLog "Microsoft-Windows-DSC/$Channel").IsEnabled
}