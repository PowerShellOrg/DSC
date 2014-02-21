
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
SetScriptWhatIfMessage=Executing the SetScript with the user supplied credential
InValidResultFromGetScriptError=Failure to get the results from the script in a hash table format.
InValidResultFromTestScriptError=Failure to get a valid result from the execution of TestScript. The Test script should return True or False.
ScriptBlockProviderScriptExecutionFailureError=Failure to successfully execute the script.
GetTargetResourceStartVerboseMessage=Begin executing Get Script.
GetTargetResourceEndVerboseMessage=End executing Get Script.
SetTargetResourceStartVerboseMessage=Begin executing Set Script.
SetTargetResourceEndVerboseMessage=End executing Set Script.
TestTargetResourceStartVerboseMessage=Begin executing Test Script.
TestTargetResourceEndVerboseMessage=End executing Test Script.
ExecutingScriptMessage=Executing Script: {0}

'@
}

$GenericMessageEventID=0x1005;
$ClassName="MSFT_ScriptResource"


Import-LocalizedData  LocalizedData -filename MSFT_ScriptResourceStrings


# The Get-TargetResource cmdlet is used to fetch the desired state of the DSC managed node through a powershell script.
# This cmdlet executes the user supplied script (i.e., the script is responsible for validating the desired state of the 
# DSC managed node). The result of the script execution is in the form of a hashtable containing all the inormation 
# gathered from the GetScript execution.
function Get-TargetResource 
{
    [CmdletBinding()]
     param 
     (         
       [parameter(Mandatory = $true)]
       [ValidateNotNullOrEmpty()]
       [string]
       $GetScript,
  
       [parameter(Mandatory = $true)]
       [ValidateNotNullOrEmpty()]
       [string]$SetScript,

       [parameter(Mandatory = $true)]
       [ValidateNotNullOrEmpty()]
       [string]
       $TestScript,

       [Parameter(Mandatory=$false)]
       [System.Management.Automation.PSCredential] 
       $Credential
     )

    $getTargetResourceResult = $null;

    $getTargetResourceStartVerboseMessage = $($LocalizedData.GetTargetResourceStartVerboseMessage);
    Write-Debug -Message $getTargetResourceStartVerboseMessage;
 
    $script = [ScriptBlock]::Create($GetScript);
    $parameters = $psboundparameters.Remove("GetScript");
    $psboundparameters.Add("ScriptBlock", $script);

    # TODO: sharatg - Remove these additional paramters once the PS infrasturcure can selectively pass input parameters.
    $parameters = $psboundparameters.Remove("SetScript");
    $parameters = $psboundparameters.Remove("TestScript");

    $scriptResult = ScriptExecutionHelper @psboundparameters;
  
    $scriptResultAsErrorRescord = $scriptResult -as [System.Management.Automation.ErrorRecord]
    if($null -ne $scriptResultAsErrorRescord)
    {
        $PSCmdlet.ThrowTerminatingError($scriptResultAsErrorRescord);
    }

    $scriptResultAsHasTable = $scriptResult -as [hashtable]

    if($null -ne $scriptResultAsHasTable)
    {
        $getTargetResourceResult = $scriptResultAsHasTable ;
    }
    else
    {
        # Error message indicating failure to get valid hashtable as the result of the Get script execution.
        $errorId = "InValidResultFromGetScript"; 
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult;
        $exception = New-Object System.InvalidOperationException $($LocalizedData.InValidResultFromGetScriptError); 
        $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord);
    }

    $getTargetResourceEndVerboseMessage = $($LocalizedData.GetTargetResourceEndVerboseMessage);
    Write-Debug -Message $getTargetResourceEndVerboseMessage;

    $getTargetResourceResult;
}


# The Set-TargetResource cmdlet is used to Set the desired state of the DSC managed node through a powershell script.
# The method executes the user supplied script (i.e., the script is responsible for validating the desired state of the 
# DSC managed node). If the DSC managed node requires a restart either during or after the execution of the SetScript,
# the SetScript notifies the PS Infrasturcure by setting the variable $DSCMachineStatus.IsRestartRequired to $true.
function Set-TargetResource 
{
    [CmdletBinding(SupportsShouldProcess=$true)]
     param 
     (       
       [parameter(Mandatory = $true)]
       [ValidateNotNullOrEmpty()]
       [string]
       $SetScript,

       [parameter(Mandatory = $true)]
       [ValidateNotNullOrEmpty()]
       [string]
       $GetScript,

       [Parameter(Mandatory=$false)]
       [System.Management.Automation.PSCredential] 
       $Credential,

       [parameter(Mandatory = $true)]
       [ValidateNotNullOrEmpty()]
       [string]
       $TestScript

 )

    $setscriptmessage = '$SetScript:' + $SetScript
    $testscriptmessage = '$TestScript:' + $TestScript
    if ($pscmdlet.ShouldProcess($($LocalizedData.SetScriptWhatIfMessage))) 
    {
        $setTargetResourceStartVerboseMessage = $($LocalizedData.SetTargetResourceStartVerboseMessage);
        Write-Debug -Message $setTargetResourceStartVerboseMessage;

        $script = [ScriptBlock]::Create($SetScript);
        $parameters = $psboundparameters.Remove("SetScript");
        $psboundparameters.Add("ScriptBlock", $script);

        $parameters = $psboundparameters.Remove("GetScript");
        $parameters = $psboundparameters.Remove("TestScript");

        $scriptResult = ScriptExecutionHelper @psboundparameters ;

        $scriptResultAsErrorRescord = $scriptResult -as [System.Management.Automation.ErrorRecord]
        if($null -ne $scriptResultAsErrorRescord)
        {
            $PSCmdlet.ThrowTerminatingError($scriptResultAsErrorRescord);
        }
        
        $setTargetResourceEndVerboseMessage = $($LocalizedData.SetTargetResourceEndVerboseMessage);
        Write-Debug -Message $setTargetResourceEndVerboseMessage; 
    }
}


# The Test-TargetResource cmdlet is used to validate the desired state of the DSC managed node through a powershell script.
# The method executes the user supplied script (i.e., the script is responsible for validating the desired state of the 
# DSC managed node). The result of the script execution should be true if the DSC managed machine is in the desired state
# or else false should be returned.
function Test-TargetResource 
{
    param 
    (       
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $TestScript,
  
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SetScript,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$GetScript,

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential] 
        $Credential
    )
    $testTargetResourceResult = $false;

    $testTargetResourceStartVerboseMessage = $($LocalizedData.TestTargetResourceStartVerboseMessage);
    Write-Debug -Message $testTargetResourceStartVerboseMessage;

    $script = [ScriptBlock]::Create($TestScript);
    $parameters = $psboundparameters.Remove("TestScript");
    $psboundparameters.Add("ScriptBlock", $script);

    $parameters = $psboundparameters.Remove("GetScript");
    $parameters = $psboundparameters.Remove("SetScript");
     
    $scriptResult = ScriptExecutionHelper @psboundparameters ;

    $scriptResultAsErrorRescord = $scriptResult -as [System.Management.Automation.ErrorRecord]
    if($null -ne $scriptResultAsErrorRescord)
    {
        $PSCmdlet.ThrowTerminatingError($scriptResultAsErrorRescord);
    }

    if($null -eq $scriptResult)
    {
        $errorId = "InValidResultFromTestScript"; 
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult;
        $exception = New-Object System.InvalidOperationException $($LocalizedData.InValidResultFromTestScriptError) ;
        $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord);
    }

    # If the script is returing multiple objects, then we consider the last object to be the result of script execution.
    if($scriptResult.GetType().ToString() -eq 'System.Object[]')
    {
        $reultObject = $scriptResult[$scriptResult.Length -1];
    }
    else
    {
        $reultObject = $scriptResult;
    }

    if(($null -ne $reultObject) -and 
       (($reultObject -eq $true) -or ($reultObject -eq $false)))
    {
        $testTargetResourceResult = $reultObject;
    }
    else
    {
        $errorId = "InValidResultFromTestScript"; 
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult;
        $exception = New-Object System.InvalidOperationException $($LocalizedData.InValidResultFromTestScriptError) ;
        $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord);
    }

    $testTargetResourceEndVerboseMessage = $($LocalizedData.TestTargetResourceEndVerboseMessage);
    Write-Debug -Message $testTargetResourceEndVerboseMessage;

    $testTargetResourceResult;
}


function ScriptExecutionHelper 
{
    param 
    (
        [ScriptBlock] 
        $ScriptBlock,
    
        [System.Management.Automation.PSCredential] 
        $Credential
    )

    $scriptExecutionResult = $null;

    try
    {

        $executingScriptMessage = $($LocalizedData.ExecutingScriptMessage) -f ${ScriptBlock} ;
        Write-Debug -Message $executingScriptMessage;

       if($null -ne $Credential)
       {
          $scriptExecutionResult = Invoke-Command -ScriptBlock $ScriptBlock -ComputerName . -Credential $Credential
       }
       else
       {
          $scriptExecutionResult = &$ScriptBlock;
       }
        $scriptExecutionResult;
    }
    catch
    {
        # Surfacing the error thrown by the execution of Get/Set/Test script.
        $_;
    }
}

Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource
