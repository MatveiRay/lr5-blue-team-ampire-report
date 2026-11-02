param([Parameter(Mandatory=$true)][string]$InputDocx,[Parameter(Mandatory=$true)][string]$OutputPdf,[switch]$UpdateAndSave)
$ErrorActionPreference='Stop'
$sourcePath=(Resolve-Path -LiteralPath $InputDocx).Path
$targetPath=[IO.Path]::GetFullPath($OutputPdf)
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($targetPath)) | Out-Null
$wordApp=$null
$wordDoc=$null
$existingWordIds=@(Get-Process WINWORD -ErrorAction SilentlyContinue | ForEach-Object {$_.Id})
$ownedWordIds=@()
try {
    $wordApp=New-Object -ComObject Word.Application
    $wordApp.Visible=$false
    $wordApp.DisplayAlerts=0
    $ownedWordIds=@(Get-Process WINWORD -ErrorAction SilentlyContinue | Where-Object {$_.Id -notin $existingWordIds} | ForEach-Object {$_.Id})
    if($ownedWordIds.Count -ne 1){throw 'Could not isolate the owned Word renderer process.'}
    $wordDoc=$wordApp.Documents.Open($sourcePath,$false,$true)
    if ($UpdateAndSave) {
        $wordDoc.Fields.Update() | Out-Null
        $wordDoc.Repaginate()
    }
    $wordDoc.ExportAsFixedFormat($targetPath,17)
    Write-Output ('DOCX rendered: '+$wordDoc.ComputeStatistics(2)+' pages')
} finally {
    # The renderer opens the source read-only. Stop only the new process owned
    # by this invocation so hidden COM save dialogs cannot stall the build.
    foreach($ownedId in $ownedWordIds){Stop-Process -Id $ownedId -Force -ErrorAction SilentlyContinue}
    if($wordDoc){[Runtime.InteropServices.Marshal]::ReleaseComObject($wordDoc) | Out-Null}
    if($wordApp){[Runtime.InteropServices.Marshal]::ReleaseComObject($wordApp) | Out-Null}
}
