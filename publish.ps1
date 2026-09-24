$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-Location -LiteralPath $PSScriptRoot
$log = Join-Path $PSScriptRoot 'publish-log.txt'
Start-Transcript -Path $log -Append | Out-Null

try {
  Write-Host '========================================'
  Write-Host 'Math in Computer Science - Publish'
  Write-Host '========================================'
  Write-Host "Repo: $PSScriptRoot"
  Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
  Write-Host ''

  if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git not found. Please install Git for Windows.' }
  if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw 'node not found. Please install Node.js.' }
  if (-not (Test-Path -LiteralPath 'scripts/prepare-content.mjs')) { throw 'scripts/prepare-content.mjs not found.' }

  Write-Host '[1/6] Preparing Quartz content...'
  node 'scripts/prepare-content.mjs'
  if ($LASTEXITCODE -ne 0) { throw 'node scripts/prepare-content.mjs failed.' }

  Write-Host '[2/6] Checking public notes contain no image embeds...'
  $files = @(Get-ChildItem -File -Filter 'Day*.md') + @(Get-ChildItem -Path 'content' -File -Filter 'Day*.md')
  $hits = $files | Select-String -Pattern '!\[\[','!\[[^\]]*\]\(' -ErrorAction SilentlyContinue
  if ($hits) {
    $hits | ForEach-Object { Write-Host ($_.Path + ':' + $_.LineNumber + ' ' + $_.Line) }
    throw 'Public notes still contain image embeds. Convert images to text before publishing.'
  }

  Write-Host '[3/6] Checking local-only folders are ignored...'
  git check-ignore -q 'assets/'
  if ($LASTEXITCODE -ne 0) { throw 'assets/ is not ignored by git.' }
  git check-ignore -q '本地图片版/Day1 数学地图与函数画图.md'
  if ($LASTEXITCODE -ne 0) { throw '本地图片版/ is not ignored by git.' }

  Write-Host '[4/6] Staging changes...'
  git add -A
  if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }

  # Defensive check after staging: no local images should be staged.
  $staged = git diff --cached --name-only
  $bad = $staged | Where-Object { $_ -match '(^|/)(assets|本地图片版|__contact_sheets)/' }
  if ($bad) {
    $bad | ForEach-Object { Write-Host "Blocked staged local-only file: $_" }
    git reset -- $bad | Out-Null
    throw 'Local-only files were staged. Aborted.'
  }

  git diff --cached --quiet
  if ($LASTEXITCODE -eq 0) {
    Write-Host 'No changes to commit.'
  } else {
    Write-Host '[5/6] Committing changes...'
    $msg = 'Update notes for GitHub Pages ' + (Get-Date -Format 'yyyy-MM-dd HHmm')
    git commit -m $msg
    if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
  }

  Write-Host '[6/6] Pushing to GitHub...'
  git push
  if ($LASTEXITCODE -ne 0) { throw 'git push failed. Check network or GitHub login.' }

  Write-Host ''
  Write-Host 'SUCCESS: pushed to GitHub. GitHub Pages will redeploy automatically.'
  Write-Host 'URL: https://condaile191-lgtm.github.io/Math-in-Computer-Science/'
}
catch {
  Write-Host ''
  Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
  Write-Host "Log: $log"
  exit 1
}
finally {
  Stop-Transcript | Out-Null
}
