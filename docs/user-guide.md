# Common Apps Manager — User Guide

A small Windows tool with a checkbox interface for installing, uninstalling, and
updating common applications. It drives WinGet (and DISM for Windows Features)
so you don't have to remember package IDs or type commands.

---

## Requirements

- 64-bit Windows 10 or Windows 11
- WinGet — ships with Windows 11 and current Windows 10; otherwise install
  **App Installer** from the Microsoft Store
- Windows PowerShell 5.1 or PowerShell 7+ (both work)
- **Administrator** — see below

### Run it as Administrator

The tool starts without elevation and will show you what is installed, but:

- machine-wide installers may silently fail or pop their own elevation prompt
- **Windows Features (.NET Framework 3.5) cannot be installed at all**

Right-click PowerShell or Windows Terminal and choose **Run as administrator**
before launching. The log panel warns you at startup when you are not elevated.

---

## Running the tool

**From the web** (once published to GitHub Pages):

```powershell
irm https://win.knk24.com | iex
```

**From a local copy:**

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Install-Common-Apps-GUI.ps1"
```

If you are already in a PowerShell prompt in that folder, `.\Install-Common-Apps-GUI.ps1`
is enough. Should execution policy block it, either use the `-ExecutionPolicy Bypass`
form above or run:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

That relaxes the policy for the current window only.

---

## The window

```
+--------------------------------------------------------------+
|  [Search apps...]                      [Select All]  [Clear]  |
|                                                               |
|  Browsers                                                     |
|    [x] Google Chrome  * Installed   [ ] Brave Browser  o ...  |
|    [ ] Waterfox       o Not installed                         |
|  Utilities                                                    |
|    [x] 7-Zip          * Installed   [ ] WinRAR         o ...  |
|                                                               |
|  +---------------------------------------------------------+  |
|  | [21:44:02] Installing Brave.Brave ...                   |  |
|  | [21:44:31] Brave Browser : Install completed.           |  |
|  +---------------------------------------------------------+  |
|                                                               |
|  [Install] [Uninstall] [Update] [Update All] [Refresh]  Ready |
+--------------------------------------------------------------+
```

### Status indicators

Each app shows its state immediately after its name:

| Indicator           | Meaning                                        |
|---------------------|------------------------------------------------|
| `* Installed`       | Detected on this machine (green)               |
| `o Not installed`   | Not detected (grey)                            |
| `checking...`       | Detection still running                        |
| `working...`        | An action is currently running on this app     |

Detection runs automatically at startup and takes roughly 20–25 seconds for the
full list. The window stays usable while it runs.

### Search

Type in the search box to filter by app name. Empty categories hide themselves.
**Select All** and **Clear** apply only to what is currently visible, so you can
search `browser`, click Select All, and act on just those.

### Layout

The window is responsive. Apps flow into three columns on a wide window, two on
a medium one, and a single column when narrow; the action buttons stack
vertically when the window gets narrow. Resize it however suits you.

---

## The buttons

| Button             | What it does                                                                        |
|--------------------|-------------------------------------------------------------------------------------|
| **Install**        | Installs every ticked app. Apps already installed are skipped, not reinstalled.      |
| **Uninstall**      | Removes every ticked app. Asks for confirmation with the list first.                 |
| **Update**         | Upgrades every ticked app. Apps that are not installed are skipped.                  |
| **Update All**     | Upgrades everything currently detected as installed. Ignores the checkboxes.         |
| **Refresh Status** | Re-runs detection for the whole list.                                                |

While a task runs, the buttons disable and the status text on the right shows
the current app. Closing the window mid-task asks for confirmation.

---

## Reading the log

Everything WinGet and DISM print streams into the log panel at the bottom, with
progress spinners and progress bars filtered out. Each action finishes with a
summary:

```
Install summary - Succeeded: 3, Skipped: 1, Failed: 0
  + Brave Browser, LocalSend, 7-Zip
  = Google Chrome
```

`+` succeeded, `=` skipped, `-` failed.

The same text is written to a log file, one per session:

```
%TEMP%\Winget-App-Installer\GUI-<date>_<time>.log
```

Paste that path into Explorer's address bar to open the folder.

---

## What is in the list

23 entries across seven categories:

- **Browsers** — Google Chrome, Brave Browser, Waterfox, Zen Browser, LibreWolf, Helium
- **Communication** — WhatsApp, Telegram Desktop
- **Remote Access** — AnyDesk, UltraViewer
- **Cloud Storage** — Dropbox, Google Drive, pCloud Drive
- **Documents & Editors** — Adobe Acrobat Reader 64-bit, Simplenote, Sublime Text 4
- **Utilities** — 7-Zip, WinRAR, Lightshot, LocalSend, Files, Windows Terminal
- **Windows Features** — .NET Framework 3.5 (includes .NET 2.0 and 3.0)

---

## Customising the list

Open `Install-Common-Apps-GUI.ps1` and find the banner near the top:

```
# ===========================================================================
# EDIT YOUR APP LIST HERE
```

Each app is one line. To add one, copy an existing line and change the fields:

```powershell
[PSCustomObject]@{ Name = "Notepad++"; Id = "Notepad++.Notepad++"; Source = "winget"; Category = "Utilities"; DetectNames = @("Notepad++*"); AppxPattern = $null }
```

| Field         | Purpose                                                                     |
|---------------|-----------------------------------------------------------------------------|
| `Name`        | The label shown in the window                                                |
| `Id`          | Exact WinGet package ID                                                      |
| `Source`      | `winget` or `msstore`                                                        |
| `Category`    | Group header. Keep entries of the same category next to each other           |
| `DetectNames` | Wildcard patterns matched against installed program names, for detection     |
| `AppxPattern` | Store/Appx package pattern, or `$null` for ordinary desktop apps             |

Find a package ID with:

```powershell
winget search "notepad++"
```

Use the value in the **Id** column exactly as shown.

### Adding a Windows Feature

Windows optional features are installed through DISM rather than WinGet. Add
`Type = "Feature"` and use the DISM feature name as the `Id`:

```powershell
[PSCustomObject]@{ Name = "Hyper-V"; Id = "Microsoft-Hyper-V-All"; Source = "feature"; Category = "Windows Features"; DetectNames = @(); AppxPattern = $null; Type = "Feature" }
```

List available feature names with:

```powershell
Get-WindowsOptionalFeature -Online | Select-Object FeatureName, State
```

Features always require Administrator and have no separate update action.

After editing, if you publish the tool to the web, run `.\Publish-Docs.ps1` so
the served copy picks up your changes.

---

## Troubleshooting

**"requires Administrator" when installing .NET Framework 3.5**
Close the tool and relaunch PowerShell with **Run as administrator**.

**.NET Framework 3.5 fails on a work or school machine**
Windows Update is often blocked by policy, and that is where the .NET 3.5 files
come from. Use Windows installation media instead — mount the ISO, then run in
an elevated prompt (replace `D:` with the mounted drive):

```powershell
dism /online /enable-feature /featurename:NetFx3 /all /source:D:\sources\sxs /limitaccess
```

**"A RESTART IS REQUIRED to finish"**
Normal for Windows Features. Reboot when convenient; the feature completes then.

**An app says it failed with an exit code**
Common WinGet outcomes are handled and reported as skips rather than errors:
another version already installed, or nothing to upgrade. Anything else is a
genuine installer failure — the log shows WinGet's own output just above the
error line, which usually explains it.

**Adobe Acrobat Reader fails with 1603**
Almost always an existing Acrobat or Reader installation conflicting. Check
Settings > Apps for an existing Adobe Acrobat entry and remove it first.

**"WinGet was not found"**
Install **App Installer** from the Microsoft Store, then reopen the tool.

**An app shows as not installed but you know it is there**
Detection matches WinGet package IDs, installed program names, and Store package
names. An app installed by an unusual method may miss all three. Add a matching
wildcard to that entry's `DetectNames`.

**Nothing happens / a wall of red errors**
Make sure you are on Windows and using PowerShell rather than Command Prompt.
If you launched with `-MTA`, the window cannot open — start PowerShell normally.

---

## Publishing your own copy

The tool can be served from GitHub Pages so any machine can run it with one
line. Run:

```powershell
.\Publish-Docs.ps1
```

This regenerates the `docs\` folder from the script. Set your domain in
`docs\CNAME`, commit, push, and point GitHub Pages at the `docs` folder
(Settings > Pages > Source: main / /docs).

Never edit `docs\index.html`, `docs\win.ps1`, or `docs\user-guide.md` by hand —
they are generated, and your changes would be overwritten on the next publish.
Edit `Install-Common-Apps-GUI.ps1` (or `_data\User-Guide.md` for this page) and
republish instead.
