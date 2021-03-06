param(
    [parameter(ParameterSetName="manual")]
    [string]$SourceDictionary,
    [parameter(ParameterSetName="manual")]
    [string]$TargetDictionary,
    [parameter(ParameterSetName="auto")]
    [switch]$AutoUpdateFiles,
    [parameter(ParameterSetName="update")]
    [string]$Update
)

$Global:ErrorActionPreference = "Stop"
[System.Reflection.Assembly]::LoadWithPartialName("System.Xml.Linq") | Out-Null

function UpdateFile()
{
    param(
        [string]$sourceFile,
        [string]$targetFile
    )

    if (!(Test-Path $targetFile))
    {
        Copy-Item $sourceFile $targetFile
        return
    }

    # foreach will stop working if we modify the collection we are going through
    # use this temp source just for the foreach loop
    [xml]$tempSource = Get-Content $sourceFile
    [xml]$source = Get-Content $sourceFile
    [xml]$target = Get-Content $targetFile

    foreach ($node in $tempSource.ResourceDictionary.ChildNodes)
    {
        if (!$node.Key)
        {
            continue
        }

        $targetNode = $target.ResourceDictionary.ChildNodes | Where-Object { $_.Key -eq $node.Key }
        $sourceNode = $source.ResourceDictionary.ChildNodes | Where-Object { $_.Key -eq $node.Key }

        if ($targetNode)
        {
            $importNode = $source.ImportNode($targetNode, $true)
            $source.ResourceDictionary.ReplaceChild($importNode, $sourceNode) | Out-Null
        }
    }

    [System.Xml.Linq.XDocument]::Parse($source.OuterXml).ToString() | Out-File -FilePath $targetFile -Encoding utf8
}

$locFolder = "..\source\PlayniteUI\Localization\"
$baseDict = Join-Path $locFolder "english.xaml"

if ($AutoUpdateFiles)
{
    foreach ($locFile in (Get-ChildItem $locFolder | Where-Object { $_.Name -ne "english.xaml" }))
    {
        UpdateFile $baseDict (Join-Path $locFolder $locFile)
    }
}
elseif ($Update)
{
    $targetDir = Join-Path $locFolder "$Update.xaml"
    UpdateFile $baseDict $targetDir
}
else
{
    UpdateFile $SourceDictionary $TargetDictionary
}