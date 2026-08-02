#Requires -Version 5.1

<#
.SYNOPSIS
    Publishes Install-Common-Apps-GUI.ps1 into the docs\ folder for GitHub Pages.

.DESCRIPTION
    GitHub Pages (Settings > Pages > Source: main / docs) serves the docs\
    folder at the site root. This script regenerates the served copies from the
    single source script so they can never drift:

        docs\index.html  Served at https://<domain>/ . Contains the full script
                         behind a PowerShell block comment that holds an HTML
                         redirect, so 'irm https://<domain> | iex' gets runnable
                         code while a browser visiting the URL is sent to the
                         human-readable install page.
        docs\win.ps1     The same script at an explicit .ps1 URL.

    Everything else in docs\ is hand-written and never touched by this script:
    user-guide.md is authored directly, and install.html, CNAME, and .nojekyll
    are only created when missing.

    This script never reads from _data\, which is a personal scratch folder and
    is not part of the published site.

    Everything is written as UTF-8 without a BOM. A BOM would end up at the
    start of the string 'irm' returns and break 'iex'.

.EXAMPLE
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Publish-Docs.ps1"

.EXAMPLE
    .\Publish-Docs.ps1 -Domain win.example.com
#>

[CmdletBinding()]
param(
    # Custom domain written to docs\CNAME when that file does not exist yet.
    [string]$Domain = "win.knk24.com"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RootDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceScript = Join-Path $RootDirectory "Install-Common-Apps-GUI.ps1"
$DocsDirectory = Join-Path $RootDirectory "docs"

if (-not (Test-Path $SourceScript)) {
    throw "Source script not found: $SourceScript"
}

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$ScriptText = [System.IO.File]::ReadAllText($SourceScript)

# ---------------------------------------------------------------------------
# Pre-flight checks on the script that is about to be served publicly
# ---------------------------------------------------------------------------

$ParseErrors = $null
$Tokens = $null
[void][System.Management.Automation.Language.Parser]::ParseInput(
    $ScriptText, [ref]$Tokens, [ref]$ParseErrors
)

if ($ParseErrors.Count -gt 0) {
    $ParseErrors | ForEach-Object {
        Write-Host ("  line {0}: {1}" -f $_.Extent.StartLineNumber, $_.Message) -ForegroundColor Red
    }
    throw "Refusing to publish: the source script has parse errors."
}

$NonAscii = @($ScriptText.ToCharArray() | Where-Object { [int]$_ -gt 127 })

if ($NonAscii.Count -gt 0) {
    $Samples = ($NonAscii | Select-Object -Unique -First 5 | ForEach-Object { "U+{0:X4}" -f [int]$_ }) -join " "
    Write-Warning "Source contains $($NonAscii.Count) non-ASCII character(s) ($Samples). These can be corrupted by charset guessing when fetched with 'irm'. Prefer regex escapes such as \u2588."
}

New-Item -Path $DocsDirectory -ItemType Directory -Force | Out-Null

# ---------------------------------------------------------------------------
# docs\win.ps1 - plain copy at an explicit URL
# ---------------------------------------------------------------------------

$WinPs1Path = Join-Path $DocsDirectory "win.ps1"
[System.IO.File]::WriteAllText($WinPs1Path, $ScriptText, $Utf8NoBom)
Write-Host "Wrote $WinPs1Path" -ForegroundColor Green

# ---------------------------------------------------------------------------
# docs\index.html - runnable by iex, redirects real browsers
# ---------------------------------------------------------------------------
#
# PowerShell treats everything between <# and #> as a comment, so the HTML
# below is invisible to 'iex'. A browser ignores the stray "<#" text, then
# honours the meta refresh. The HTML must never contain the sequence #>.

$RedirectHeader = @'
<# :
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta http-equiv="refresh" content="0; url=./install.html">
<title>Common Apps Manager</title>
</head>
<body>
Redirecting to the <a href="./install.html">install instructions</a>.
</body>
</html>
#>
'@

$IndexPath = Join-Path $DocsDirectory "index.html"
$IndexText = $RedirectHeader + "`r`n" + $ScriptText
[System.IO.File]::WriteAllText($IndexPath, $IndexText, $Utf8NoBom)
Write-Host "Wrote $IndexPath" -ForegroundColor Green

# Prove the generated file is still valid PowerShell after the header was added.
$IndexParseErrors = $null
$IndexTokens = $null
[void][System.Management.Automation.Language.Parser]::ParseInput(
    $IndexText, [ref]$IndexTokens, [ref]$IndexParseErrors
)

if ($IndexParseErrors.Count -gt 0) {
    $IndexParseErrors | ForEach-Object {
        Write-Host ("  line {0}: {1}" -f $_.Extent.StartLineNumber, $_.Message) -ForegroundColor Red
    }
    throw "Generated index.html is not valid PowerShell."
}

# ---------------------------------------------------------------------------
# docs\user-guide.md - hand-written, never generated
# ---------------------------------------------------------------------------
#
# The user guide is authored directly in docs\ and committed. This script does
# not touch it. Nothing here reads from _data\, which is a personal scratch
# folder, git-ignored, and deliberately kept out of the published site.

$GuidePath = Join-Path $DocsDirectory "user-guide.md"

if (-not (Test-Path $GuidePath)) {
    Write-Warning "docs\user-guide.md is missing; the landing page links to it. Restore it from git."
}

# ---------------------------------------------------------------------------
# Files created once, then left alone so hand edits survive
# ---------------------------------------------------------------------------

$NoJekyllPath = Join-Path $DocsDirectory ".nojekyll"

if (-not (Test-Path $NoJekyllPath)) {
    # Stops GitHub Pages running the files through Jekyll.
    [System.IO.File]::WriteAllText($NoJekyllPath, "", $Utf8NoBom)
    Write-Host "Created $NoJekyllPath" -ForegroundColor Cyan
}

$CnamePath = Join-Path $DocsDirectory "CNAME"

if (-not (Test-Path $CnamePath)) {
    [System.IO.File]::WriteAllText($CnamePath, "$Domain`n", $Utf8NoBom)
    Write-Host "Created $CnamePath ($Domain)" -ForegroundColor Cyan
}
else {
    $Domain = ([System.IO.File]::ReadAllText($CnamePath)).Trim()
}

$InstallPagePath = Join-Path $DocsDirectory "install.html"

if (-not (Test-Path $InstallPagePath)) {
    $InstallPage = @'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Common Apps Manager</title>
<style>
  :root { color-scheme: dark; }
  body {
    margin: 0; padding: 48px 20px;
    background: #1b1b1b; color: #f0f0f0;
    font: 16px/1.6 "Segoe UI", system-ui, sans-serif;
  }
  main { max-width: 720px; margin: 0 auto; }
  h1 { font-size: 28px; margin: 0 0 8px; }
  p.lead { color: #9e9e9e; margin: 0 0 32px; }
  h2 { font-size: 17px; margin: 32px 0 8px; color: #58a6ff; }
  pre {
    background: #141414; border: 1px solid #3f3f46; border-radius: 6px;
    padding: 14px 16px; overflow-x: auto;
    font: 13px/1.5 Consolas, monospace; color: #d4d4d4;
  }
  ul { padding-left: 20px; color: #d0d0d0; }
  li { margin: 6px 0; }
  .warn {
    border-left: 3px solid #e0c341; background: #241f0d;
    padding: 12px 16px; border-radius: 0 4px 4px 0; margin: 24px 0;
  }
  footer { margin-top: 40px; color: #6e6e6e; font-size: 13px; }
  a { color: #58a6ff; }
</style>
</head>
<body>
<main>
  <h1>Common Apps Manager</h1>
  <p class="lead">A small WPF tool that installs, uninstalls, and updates common Windows applications through WinGet.</p>

  <h2>Run it</h2>
  <p>Open <strong>PowerShell as Administrator</strong> and run:</p>
  <pre>irm https://DOMAIN_PLACEHOLDER | iex</pre>

  <div class="warn">
    Run as Administrator. Machine-wide installers and Windows Features such as
    .NET Framework 3.5 cannot be installed without it.
  </div>

  <h2>What it does</h2>
  <ul>
    <li>Shows every app in the list with its current installed status.</li>
    <li>Tick what you want, then Install, Uninstall, or Update.</li>
    <li>Update All upgrades everything already installed.</li>
    <li>Live output in the window, plus a log in <code>%TEMP%\Winget-App-Installer</code>.</li>
  </ul>

  <h2>Requirements</h2>
  <ul>
    <li>64-bit Windows 10 or Windows 11.</li>
    <li>WinGet (Microsoft App Installer).</li>
    <li>Windows PowerShell 5.1 or PowerShell 7+.</li>
  </ul>

  <h2>More</h2>
  <ul>
    <li><a href="./user-guide.md">User guide</a> &mdash; every button, customising the app list, troubleshooting.</li>
  </ul>

  <footer>
    Read the source before running it:
    <a href="./win.ps1">win.ps1</a>
  </footer>
</main>
</body>
</html>
'@

    $InstallPage = $InstallPage.Replace("DOMAIN_PLACEHOLDER", $Domain)
    [System.IO.File]::WriteAllText($InstallPagePath, $InstallPage, $Utf8NoBom)
    Write-Host "Created $InstallPagePath" -ForegroundColor Cyan
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "Published to $DocsDirectory" -ForegroundColor White
Write-Host "  Users run : irm https://$Domain | iex" -ForegroundColor Gray
Write-Host "  Direct    : irm https://$Domain/win.ps1 | iex" -ForegroundColor Gray
Write-Host ""
Write-Host "Commit and push, then set GitHub Pages source to 'main' / '/docs'." -ForegroundColor DarkGray
