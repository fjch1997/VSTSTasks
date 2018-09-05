$outputDirectory = (Get-Item -Path ".\" -Verbose).FullName + "\bin"
foreach ($_ in Get-ChildItem -Recurse -Filter "vss-extension.json")
{
	cd $_.DirectoryName
	tfx extension create --manifests $_.FullName --OutputPath $outputDirectory
}