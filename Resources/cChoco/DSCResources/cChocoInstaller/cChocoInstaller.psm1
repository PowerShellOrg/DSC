function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstallDir
    )
    Write-Verbose " Start Get-TargetResource"


    #Needs to return a hashtable that returns the current
    #status of the configuration component
    $Configuration = @{
        InstallDir = $InstallDir
    }

    if (-not (IsChocoInstalled))
    {
        #$Configuration.Ensure = "Absent"
        Return $Configuration
    }
    else
    {
        #$Configuration.Ensure = "Present"
        Return $Configuration

    }
}

function Set-TargetResource
{
    [CmdletBinding()]    
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstallDir
    )
    Write-Verbose " Start Set-TargetResource"
    
    if (-not (DoesCommandExist choco) -or -not (IsChocoInstalled))
    {
        #$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine')

        Write-Verbose '[ChocoInstaller] Start InstallChoco'
        InstallChoco $InstallDir
        Write-Verbose '[ChocoInstaller] Finish InstallChoco'

        #refresh path varaible in powershell, as choco doesn"t, to pull in git
        #$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstallDir
    )

    Write-Verbose " Start Test-TargetResource"

    if (-not (IsChocoInstalled))
    {
        Return $false
    }

    Return $true
}

function IsChocoInstalled
{

    Write-Verbose " Is choco installed? "

    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")

    if (DoesCommandExist choco)
    {
        Write-Verbose " YES - Choco is Installed"

        return $true
    }

    Write-Verbose " NO - Choco isn't Installed"

    return $false

    
}


function ExecPowerShellScript
{
    param(
        [Parameter(Position=1,Mandatory=0)][string]$block
    )

    $location = Get-Location
    Write-Verbose " ExecPowerShellScriptBlock Prep Setting Current Location: $location"

    $psi = New-object System.Diagnostics.ProcessStartInfo 
    $psi.CreateNoWindow = $false 
    $psi.UseShellExecute = $false 
    $psi.RedirectStandardOutput = $true 
    $psi.RedirectStandardError = $true 
    $psi.FileName = "powershell" 
    $psi.WorkingDirectory = $location.ToString()
    $psi.Arguments = "-ExecutionPolicy Unrestricted -command $block" 
    $process = New-Object System.Diagnostics.Process 
    $process.StartInfo = $psi
    $process.Start() | Out-Null
    $process.WaitForExit()
    $output = $process.StandardOutput.ReadToEnd() + $process.StandardError.ReadToEnd()

    Write-Verbose " Exec powershell Command - $block"

    return $output
}

function DoesCommandExist
{
    Param ($command)

    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'

    try 
    {
        if(Get-Command $command)
        {
            return $true
        }
    }
    Catch 
    {
        return $false
    }
    Finally {
        $ErrorActionPreference=$oldPreference
    }
} 


##region - chocolately installer work arounds. Main issue is use of write-host
##attempting to work around the issues with Chocolatey calling Write-host in its scripts. 
function global:Write-Host
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Object]
        $Object,
        [Switch]
        $NoNewLine,
        [ConsoleColor]
        $ForegroundColor,
        [ConsoleColor]
        $BackgroundColor

    )

    #Override default Write-Host...
    Write-Verbose $Object
}

## Adapated version of the Chocolatey install script, now using write-verbose

# ==============================================================================
# 
# Fervent Coder Copyright 2011 - Present - Released under the Apache 2.0 License
# 
# Copyright 2007-2008 The Apache Software Foundation.
#  
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use 
# this file except in compliance with the License. You may obtain a copy of the 
# License at 
#
#     http://www.apache.org/licenses/LICENSE-2.0 
# 
# Unless required by applicable law or agreed to in writing, software distributed 
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR 
# CONDITIONS OF ANY KIND, either express or implied. See the License for the 
# specific language governing permissions and limitations under the License.
# ==============================================================================

# variables
$url = "http://chocolatey.org/api/v2/package/chocolatey/"
$chocTempDir = Join-Path $env:TEMP "chocolatey"
$tempDir = Join-Path $chocTempDir "chocInstall"
if (![System.IO.Directory]::Exists($tempDir)) {[System.IO.Directory]::CreateDirectory($tempDir)}
$file = Join-Path $tempDir "chocolatey.zip"

function Download-File {
    param (
      [string]$url,
      [string]$file
     )
  Write-verbose "Downloading $url to $file"
  $downloader = new-object System.Net.WebClient
  $downloader.Proxy.Credentials=[System.Net.CredentialCache]::DefaultNetworkCredentials;
  $downloader.DownloadFile($url, $file)
}

function InstallChoco
{
    param (
            [string]$ChocoInstallDir
    )
    # download the package
    Download-File $url $file
    
    # download 7zip
    Write-verbose "Download 7Zip commandline tool"
    $7zaExe = Join-Path $tempDir '7za.exe'
    
    Download-File 'http://chocolatey.org/7za.exe' "$7zaExe"
    
    
    # unzip the package
    Write-verbose "Extracting $file to $tempDir..."
    Start-Process "$7zaExe" -ArgumentList "x -o`"$tempDir`" -y `"$file`"" -Wait
    #$shellApplication = new-object -com shell.application 
    #$zipPackage = $shellApplication.NameSpace($file) 
    #$destinationFolder = $shellApplication.NameSpace($tempDir) 
    #$destinationFolder.CopyHere($zipPackage.Items(),0x10)
    
    # call chocolatey install
    Write-verbose "Installing chocolatey on this machine"
    $toolsFolder = Join-Path $tempDir "tools"
    #$chocInstallPS1 = Join-Path $toolsFolder "chocolateyInstall.ps1"
    
    $toolsPath = $toolsFolder
    $installFolder = $ChocoInstallDir

    $scriptBlock =    "Write-verbose 'Choco Install SriptBlock Start'
    Write-verbose 'tools folder:'
    Write-verbose $toolsPath
    Write-verbose 'install folder:' 
    Write-verbose  $installFolder
    if ((Test-Path  $installFolder))
    {
        Write-verbose 'install folder already exists at $installFolder'
    }
    else
    {
        #Write-verbose 'creating install folder at $installFolder'
        New-Item -ItemType directory -Path $installFolder
    }
    Set-Location $toolsPath
    # ensure module loading preference is on
    `$PSModuleAutoLoadingPreference = 'All'
    `$modules = Get-ChildItem $toolsPath -Filter *.psm1
    `$modules | ForEach-Object { `$psm1File = `$_.FullName;
    `$moduleName = `$([System.IO.Path]::GetFileNameWithoutExtension(`$psm1File))
    remove-module `$moduleName -ErrorAction SilentlyContinue;
    import-module -name  `$psm1File;
    }
    Initialize-Chocolatey -chocolateyPath $installFolder
    "


    #&$scriptBlock $toolsFolder $ChocoInstallDir
    $installOutput = ExecPowerShellScript $scriptBlock
    
    Write-verbose "[choco output]$installOutput"

    
    write-verbose 'Ensuring chocolatey commands are on the path'
    $chocInstallVariableName = "ChocolateyInstall"
    $chocoPath = [Environment]::GetEnvironmentVariable($chocInstallVariableName, [System.EnvironmentVariableTarget]::User)
    $chocoExePath = 'C:\Chocolatey\bin'
    if ($chocoPath -ne $null) {
      $chocoExePath = Join-Path $chocoPath 'bin'
    }
    
    if ($($env:Path).ToLower().Contains($($chocoExePath).ToLower()) -eq $false) {
      $env:Path = [Environment]::GetEnvironmentVariable('Path',[System.EnvironmentVariableTarget]::Machine);
    }
    
    # update chocolatey to the latest version
    #Write-verbose "Updating chocolatey to the latest version"
    #cup chocolatey
}


Export-ModuleMember -Function *-TargetResource