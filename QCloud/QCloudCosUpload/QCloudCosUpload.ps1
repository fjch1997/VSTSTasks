[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation
try {
    # Get the inputs.
	[string]$apiBaseUrl = Get-VstsInput -Name apiBaseUrl
	[int]$appId = Get-VstsInput -Name appId
	[string]$secretId = Get-VstsInput -Name secretId
	[string]$secretKey = Get-VstsInput -Name secretKey
	[string]$bucketName = Get-VstsInput -Name bucketName
	[string]$filesToUpload = Get-VstsInput -Name filesToUpload
	[string]$filePath = Get-VstsInput -Name filePath
	$filePath = $filePath.Trim("/")
	[string]$fileAttribute = Get-VstsInput -Name fileAttribute
	[bool]$insertOnly = Get-VstsInput -Name insertOnly -AsBool
	Write-Host "Loading QCloud API"
	$cosCloudType = (Add-Type -Path ".\QCloud.CosApi\cos_api_sdk.dll" -PassThru | where Name -eq "CosCloud")
	$cosCloud = $cosCloudType.GetConstructors()[1].Invoke(@($apiBaseUrl, $appId, $secretId,$secretKey, 600))
	foreach ($fileName in (Find-VstsMatch -Pattern $filesToUpload.Split("`n"))){
		Write-Host "Uploading $fileName"
		$fileInfo = New-Object System.IO.FileInfo($fileName)
		$params = New-Object 'System.Collections.Generic.Dictionary[string,string]'
		$params.Add("biz_attr", $fileAttribute)
		if($insertOnly){ $params.Add("insertOnly", 1)}
		else { $params.Add("insertOnly", 0)}
		if([System.String]::IsNullOrWhiteSpace($filePath)) {
			$remotePath = "/" + $fileInfo.Name
		}
		else {
			$remotePath  = "/" + $filePath + "/" + $fileInfo.Name
		}
			
		$result = $cosCloud.UploadFile($bucketName, $remotePath, $fileName, $params)
			
		Write-Host $result

		$jsonResult = ConvertFrom-Json $result
		if($jsonResult.code -lt -1) {
			throw $jsonResult.message
		}
	}
} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}