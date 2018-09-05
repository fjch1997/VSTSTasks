[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation
try {
    # Get the inputs.
    [string]$fileName = Get-VstsInput -Name fileName
	[string]$variableName = Get-VstsInput -Name variableName

	$version = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($fileName).FileVersion.ToString()

	Write-Host "File version for $fileName is $version"

	Set-VstsTaskVariable -Name $variableName -Value $version
} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}