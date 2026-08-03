# win-tools

A single-file WPF tool for setting up a fresh Windows 10/11 x64 machine: tick
the apps you want, then install, uninstall or update them through WinGet.

```powershell
irm https://win.knk24.com | iex
```

Or run a local copy:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install-Common-Apps-GUI.ps1
```

**Elevation cuts both ways.** Run as Administrator to install machine-wide
packages and Windows Features such as .NET Framework 3.5. Run *without*
Administrator to uninstall apps that live in your own user profile — most
browsers and chat apps — because WinGet refuses to remove those from an
elevated session.

## What is here

| File | |
|---|---|
| `Install-Common-Apps-GUI.ps1` | The tool. Also the source of truth for the app list. |
| `docs\user-guide.md` | Every button, customising the list, troubleshooting. |
| `Publish-Docs.ps1` | Regenerates `docs\index.html` and `docs\win.ps1` for GitHub Pages. |
| `winutil.ps1` | Vendored copy of ChrisTitusTech's WinUtil, kept as read-only reference. |

`docs\index.html` and `docs\win.ps1` are generated — edit the GUI script and
re-run `.\Publish-Docs.ps1` rather than touching them.

## Editing the app list

The catalog sits under the `EDIT YOUR APP LIST HERE` banner near the top of
`Install-Common-Apps-GUI.ps1`, one line per app. After changing it, update the
"What is in the list" section of the user guide and re-run `.\Publish-Docs.ps1`.

Full details are in the [user guide](docs/user-guide.md).
