Hello,

Thank you for evaluating cPSGet, the community DSC resource for PowerShellGet.

This resource will allow you to use the PowerShellGet module from DSC.

Example:
Configuration PSGet
{
Param ($computername)
  Import-DSCResource -ModuleName cPSGet
  Node $ComputerName
    {
      cPSGet Testing
        {
          Name = 'bing'
          Ensure = 'Present'
        } 	
    }
}

***Warning***
As of this writing, 7/18/2014, PowerShellGet requires the May WMF 5.0 preview.  On an x64 system with windows 8.1 with update the nuget.exe file used by the SYSTEM account with PowerShellGet will fail to run.

This issue has been filed with microsoft here:
https://connect.microsoft.com/PowerShell/feedback/details/922914/wmf-5-may-preview-powershellget-nuget-exe-wont-launch-when-running-as-system

You can fix this issue by replacing the nuget.exe file at %winddir%\System32\config\systemprofile\AppData\Local\Microsoft\Windows\PowerShell\PowerShellGet\nuget.exe with a working version of nuget.exe.
