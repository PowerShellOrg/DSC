function Clear-CachedDscResource {
    Write-Verbose 'Stopping any existing WMI processes to clear cached resources.'
    Get-process -Name WmiPrvSE -erroraction silentlycontinue | stop-process -force 

    Write-Verbose 'Clearing out any tmp WMI classes from tested resources.'
    Get-DscResourceWmiClass -class tmp* | remove-DscResourceWmiClass
}