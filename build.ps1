param([ValidateSet('all','docx','pdf','check','clean')][string]$Format='all')
$ErrorActionPreference='Stop'
$nativeMake=Get-Command make -ErrorAction SilentlyContinue
if($nativeMake) {
    Push-Location -LiteralPath $PSScriptRoot
    try { & $nativeMake.Source $Format; if($LASTEXITCODE -ne 0){throw "Build failed: $LASTEXITCODE"} }
    finally { Pop-Location }
} else {
    $wslCommand=Get-Command wsl -ErrorAction SilentlyContinue
    if(-not $wslCommand){throw 'GNU Make is required. Install the tools listed in README.md.'}
    $buildCommand = 'export PATH="$HOME/.local/bin:$PATH"; make ' + $Format
    & $wslCommand.Source --cd $PSScriptRoot -- sh -lc $buildCommand
    if($LASTEXITCODE -ne 0){throw "WSL build failed: $LASTEXITCODE"}
}
Write-Host 'Output: report/_output/report.docx and report/_output/report.pdf'
