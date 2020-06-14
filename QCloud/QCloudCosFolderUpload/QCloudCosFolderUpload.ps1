[CmdletBinding()]
param()
Trace-VstsEnteringInvocation $MyInvocation
function Upload-Directory {
    param ([System.IO.DirectoryInfo]$directoryInfo, [System.IO.DirectoryInfo]$rootDirectoryInfo, [string]$bucketName, $cosCloud, $params, $searchPattern)
    Write-Host "Uploading directory " $directoryInfo.FullName
    foreach ($fileInfo in $directoryInfo.EnumerateFiles($searchPattern)) {
        $remotePath = $fileInfo.FullName.Replace($rootDirectoryInfo.fullname, "").Replace("\", "/")
        Write-Host ("Uploading " + $fileInfo.FullName + " as " + $remotePath)
        $result = $cosCloud.UploadFile($bucketName, $remotePath, $fileInfo.FullName, $params)
		Write-Host $result
	    $jsonResult = ConvertFrom-Json $result
	    if($jsonResult.code -lt -1) {
		    throw $jsonResult.message
	    }
    } 
    foreach ($childDirectoryInfo in $directoryInfo.EnumerateDirectories()) {
        Upload-Directory $childDirectoryInfo $rootDirectoryInfo $bucketName $cosCloud $params $searchPattern
    }
}
try {
    # Get the inputs.
	[string]$apiBaseUrl = Get-VstsInput -Name apiBaseUrl
	[int]$appId = Get-VstsInput -Name appId
	[string]$secretId = Get-VstsInput -Name secretId
	[string]$secretKey = Get-VstsInput -Name secretKey
	[string]$bucketName = Get-VstsInput -Name bucketName
	[string]$folderToUpload = Get-VstsInput -Name folderToUpload
	[string]$fileAttribute = Get-VstsInput -Name fileAttribute
    [string]$searchPattern = Get-VstsInput -Name searchPattern
	[bool]$insertOnly = Get-VstsInput -Name insertOnly -AsBool
    ## Debug inputs.    
	#[string]$apiBaseUrl = "http://gz.file.myqcloud.com/files/v2/"
	#[int]$appId = "1252056221"
	#[string]$secretId = "AKIDvfBTWKucv3wb1C4pIWWIp8D3e192I3C6"
	#[string]$secretKey = "nMhneHfoiMktnRpyrZbQ6dx42lFSP6Yk"
	#[string]$bucketName = "steamtb"
	#[string]$folderToUpload = "C:\Users\Lloyd\Source\Repos\Dota2InventoryAnalyzer\Dota2InventoryAnalyzer.Web"
	#[string]$fileAttribute = ""
	#[string]$searchPattern = "*"
	#[bool]$insertOnly = $false

    # Do work.
	Write-Host "Loading QCloud API"
	$cosCloudType = (Add-Type -Path ".\QCloud.CosApi\cos_api_sdk.dll" -PassThru | where Name -eq "CosCloud")
	$cosCloud = $cosCloudType.GetConstructors()[1].Invoke(@($apiBaseUrl, $appId, $secretId,$secretKey, 600))
	
	Write-Host "Uploading folder $folderToUpload"
	$directoryInfo = New-Object System.IO.DirectoryInfo($folderToUpload)
	$params = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	$params.Add("biz_attr", $fileAttribute)
	if($insertOnly){ $params.Add("insertOnly", 1)}
	else { $params.Add("insertOnly", 0)}

    Upload-Directory $directoryInfo $directoryInfo $bucketName $cosCloud $params $searchPattern
	
} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}

