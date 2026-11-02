# Installs Autopilot's agent service (the `autopilot` command) from the wheel beside this script, on Windows.
#
#   powershell -ExecutionPolicy Bypass -File install.ps1
#
# It uses uv (https://docs.astral.sh/uv/), installing it first if it isn't there, and uv brings a Python 3.12 of its
# own; the agent, OpenCode, runs under Bun (https://bun.sh), installed the same way: nothing else needs to be
# installed. Run it again to update. Uninstall with `autopilot uninstall` (or Remove from this computer, on a
# plugin's Settings page).

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$settings = Join-Path $env:LOCALAPPDATA "Autopilot"
$envFile = Join-Path $settings "autopilot.env"
$wheel = Get-ChildItem -Path $here -Filter "autopilot-*.whl" | Select-Object -First 1
if (-not $wheel) { throw "No autopilot-*.whl next to install.ps1: unpack the whole download, then run it again." }

if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Host "Installing uv (https://docs.astral.sh/uv/), which installs Autopilot and its Python..."
    powershell -ExecutionPolicy Bypass -c "irm https://astral.sh/uv/install.ps1 | iex"
    $env:Path = "$env:USERPROFILE\.local\bin;$env:Path"
}

Write-Host "Installing Autopilot from $($wheel.Name)..."
# An update never leaves a broken Autopilot behind. `uv tool install --force` deletes the installed environment first,
# and a program running from it (another editor's agent service, the `autopilot mcp` a Claude Code or Codex session
# keeps open) holds files Windows won't delete: uv then stopped halfway, Lib (the autopilot package with it) gone. A
# held folder and a running .exe can still be moved, so the installed environment and its command are moved aside,
# the new one is installed where they were and checked, and on any failure the old ones are moved back. What was moved
# aside is deleted once nothing holds it (here, or by the next install).
$toolDir = "$(uv tool dir)".Trim()
$binDir = "$(uv tool dir --bin)".Trim()
if ($LASTEXITCODE -ne 0 -or -not $binDir) { $binDir = Join-Path $env:USERPROFILE ".local\bin" }  # (an older uv)
$envDir = Join-Path $toolDir "autopilot"
$command = Join-Path $binDir "autopilot.exe"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$asideDir = Join-Path (Split-Path -Parent $toolDir) "autopilot-previous"  # (not in the tool folder: uv lists those)
$envAside = Join-Path $asideDir "autopilot-$stamp"
$commandAside = "autopilot.exe.$stamp.old"  # (beside it: an .exe moves only within its drive)

function Remove-Aside {
    # (what earlier updates moved aside: a file still held stays for the next one)
    if (Test-Path $asideDir) {
        Get-ChildItem $asideDir | ForEach-Object { Remove-Item -Recurse -Force $_.FullName -ErrorAction SilentlyContinue }
    }
    Get-ChildItem $binDir -Filter "autopilot.exe.*.old" -ErrorAction SilentlyContinue |
        ForEach-Object { Remove-Item -Force $_.FullName -ErrorAction SilentlyContinue }
}

function Restore-Previous {
    if ($script:movedEnv) {
        if (Test-Path $envDir) { Remove-Item -Recurse -Force $envDir -ErrorAction SilentlyContinue }  # (what uv made of it)
        Move-Item -LiteralPath $envAside -Destination $envDir -ErrorAction SilentlyContinue
    }
    if ($script:movedCommand) {
        if (Test-Path $command) { Remove-Item -Force $command -ErrorAction SilentlyContinue }
        Rename-Item -LiteralPath (Join-Path $binDir $commandAside) -NewName "autopilot.exe" -ErrorAction SilentlyContinue
    }
    if ($script:movedEnv -and -not (Test-Path (Join-Path $envDir "Lib\site-packages\autopilot"))) {
        return " The version installed before couldn't be put back either: close every program using Autopilot, then run this again."
    }
    if ($script:movedEnv) { return " The version installed before is kept." }
    return ""
}

Remove-Aside
$script:movedEnv = $false
$script:movedCommand = $false
$inUse = ("Close what runs Autopilot (another editor's Autopilot tab, a Claude Code or Codex session using it), then " +
          "run this again. The version installed before is unchanged.")
if (Test-Path $envDir) {
    # (the command first: a running .exe can't be moved, so an agent service it runs, another editor's, leaves
    # everything as it was)
    if (Test-Path $command) {
        try { Rename-Item -LiteralPath $command -NewName $commandAside -ErrorAction Stop; $script:movedCommand = $true }
        catch { throw "Couldn't update Autopilot: $command is running. $inUse" }
    }
    New-Item -ItemType Directory -Force -Path $asideDir | Out-Null
    try { Move-Item -LiteralPath $envDir -Destination $envAside -ErrorAction Stop; $script:movedEnv = $true }
    catch {
        Restore-Previous | Out-Null
        throw "Couldn't update Autopilot: its installed files are in use ($($_.Exception.Message)). $inUse"
    }
}
# The wheel is installed from a copy dated now, in a folder of its own. uv keeps a local wheel it has unpacked by its
# path and date, and every download's files are dated alike (2026-01-01, tools/package_release.py), so a plugin updated
# in place would have uv install the build before it again, from its cache, and say it installed this one
$fresh = Join-Path ([System.IO.Path]::GetTempPath()) ("autopilot-wheel-" + [guid]::NewGuid().ToString("N"))
try {
    New-Item -ItemType Directory -Force -Path $fresh | Out-Null
    $copy = Join-Path $fresh $wheel.Name
    Copy-Item -LiteralPath $wheel.FullName -Destination $copy
    (Get-Item -LiteralPath $copy).LastWriteTime = Get-Date
}
catch {
    Remove-Item -Recurse -Force $fresh -ErrorAction SilentlyContinue
    $kept = Restore-Previous
    throw "Couldn't copy $($wheel.Name) to install it ($($_.Exception.Message)).$kept"
}
$uri = ([System.Uri]$copy).AbsoluteUri
uv tool install --force --python 3.12 "autopilot[claude,codex] @ $uri"
$installed = $LASTEXITCODE
Remove-Item -Recurse -Force $fresh -ErrorAction SilentlyContinue
if ($installed -eq 0) {
    & (Join-Path $envDir "Scripts\python.exe") -I -c "import autopilot.cli"
    if ($LASTEXITCODE -ne 0) {
        $kept = Restore-Previous
        throw "uv installed Autopilot, but it doesn't start (python -c `"import autopilot.cli`" failed).$kept"
    }
}
else {
    $kept = Restore-Previous
    throw "uv couldn't install Autopilot (exit code $installed).$kept"
}
Remove-Aside
uv tool update-shell | Out-Null

# Which agent service this is (agent-service.json beside this script), kept in the settings folder: a plugin carrying
# another one installs its own before it starts the agent service
$stamp = Join-Path $here "agent-service.json"
if (Test-Path $stamp) {
    New-Item -ItemType Directory -Force -Path $settings | Out-Null
    Copy-Item -Force $stamp (Join-Path $settings "agent-service.json")
}

# Settings the download carries (settings.env beside this script, e.g. which Aura server it was built for) go into
# autopilot.env over what is there; those an earlier download carried and this one doesn't are taken out
# (python -I, here and below: the installed Autopilot, whatever folder this runs in; from one holding a checkout's
# autopilot/, that was imported instead, and OpenCode's packages went into it)
$python = Join-Path (uv tool dir) "autopilot\Scripts\python.exe"
& $python -I -c "import sys; from autopilot import account; account.apply_download_settings(sys.argv[1])" (Join-Path $here "settings.env")
if ($LASTEXITCODE -ne 0) { throw "Couldn't save the download's settings in $envFile (exit code $LASTEXITCODE)." }

# The Coding Agents: Claude Code and Codex come with Autopilot; OpenCode, the default, runs under Bun (installed here when it
# isn't there), and its packages are fetched now, not at the first run. Without Bun, Claude Code is the default
$bun = Get-Command bun -ErrorAction SilentlyContinue
$bunHome = Join-Path $env:USERPROFILE ".bun\bin\bun.exe"
if (-not $bun -and -not (Test-Path $bunHome)) {
    Write-Host "Installing Bun (https://bun.sh), which runs the agent..."
    try { powershell -ExecutionPolicy Bypass -c "irm bun.sh/install.ps1 | iex" } catch { Write-Host "  $_" }
}
& $python -I -c "from autopilot.agents import opencode; opencode.ensure_installed(opencode.bun())"
if ($LASTEXITCODE -ne 0) {
    New-Item -ItemType Directory -Force -Path $settings | Out-Null
    $lines = @()
    if (Test-Path $envFile) { $lines = Get-Content $envFile }
    if (-not ($lines | Where-Object { $_ -match '^\s*(export\s+)?AUTOPILOT_AGENT\s*=' })) {
        Add-Content -Path $envFile -Value "AUTOPILOT_AGENT=claude"
    }
    Write-Host "OpenCode couldn't be set up under Bun, so Autopilot will use Claude Code; Codex works too (Coding Agent in the"
    Write-Host "first-run setup). Install Bun (https://bun.sh), then run this again to use OpenCode."
}

Write-Host ""
Write-Host "Autopilot is installed. Autopilot starts it with your editor: open the Autopilot tab and finish its first-run"
Write-Host "setup. To run it yourself instead, run this before you open the editor (Autopilot connects to it):"
Write-Host "  autopilot serve"

# SIG # Begin signature block
# MIIowgYJKoZIhvcNAQcCoIIoszCCKK8CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBvPnw6hUK+eZyx
# zM/Xz2Tl1xhHIphGZQZwMNfcF4LJFqCCDfcwggawMIIEmKADAgECAhAIrUCyYNKc
# TJ9ezam9k67ZMA0GCSqGSIb3DQEBDAUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNV
# BAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yMTA0MjkwMDAwMDBaFw0z
# NjA0MjgyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAw
# ggIKAoICAQDVtC9C0CiteLdd1TlZG7GIQvUzjOs9gZdwxbvEhSYwn6SOaNhc9es0
# JAfhS0/TeEP0F9ce2vnS1WcaUk8OoVf8iJnBkcyBAz5NcCRks43iCH00fUyAVxJr
# Q5qZ8sU7H/Lvy0daE6ZMswEgJfMQ04uy+wjwiuCdCcBlp/qYgEk1hz1RGeiQIXhF
# LqGfLOEYwhrMxe6TSXBCMo/7xuoc82VokaJNTIIRSFJo3hC9FFdd6BgTZcV/sk+F
# LEikVoQ11vkunKoAFdE3/hoGlMJ8yOobMubKwvSnowMOdKWvObarYBLj6Na59zHh
# 3K3kGKDYwSNHR7OhD26jq22YBoMbt2pnLdK9RBqSEIGPsDsJ18ebMlrC/2pgVItJ
# wZPt4bRc4G/rJvmM1bL5OBDm6s6R9b7T+2+TYTRcvJNFKIM2KmYoX7BzzosmJQay
# g9Rc9hUZTO1i4F4z8ujo7AqnsAMrkbI2eb73rQgedaZlzLvjSFDzd5Ea/ttQokbI
# YViY9XwCFjyDKK05huzUtw1T0PhH5nUwjewwk3YUpltLXXRhTT8SkXbev1jLchAp
# QfDVxW0mdmgRQRNYmtwmKwH0iU1Z23jPgUo+QEdfyYFQc4UQIyFZYIpkVMHMIRro
# OBl8ZhzNeDhFMJlP/2NPTLuqDQhTQXxYPUez+rbsjDIJAsxsPAxWEQIDAQABo4IB
# WTCCAVUwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUaDfg67Y7+F8Rhvv+
# YXsIiGX0TkIwHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0P
# AQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHcGCCsGAQUFBwEBBGswaTAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAC
# hjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9v
# dEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAcBgNVHSAEFTATMAcGBWeBDAED
# MAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAOiNEPY0Idu6PvDqZ01bgAhql
# +Eg08yy25nRm95RysQDKr2wwJxMSnpBEn0v9nqN8JtU3vDpdSG2V1T9J9Ce7FoFF
# UP2cvbaF4HZ+N3HLIvdaqpDP9ZNq4+sg0dVQeYiaiorBtr2hSBh+3NiAGhEZGM1h
# mYFW9snjdufE5BtfQ/g+lP92OT2e1JnPSt0o618moZVYSNUa/tcnP/2Q0XaG3Ryw
# YFzzDaju4ImhvTnhOE7abrs2nfvlIVNaw8rpavGiPttDuDPITzgUkpn13c5Ubdld
# AhQfQDN8A+KVssIhdXNSy0bYxDQcoqVLjc1vdjcshT8azibpGL6QB7BDf5WIIIJw
# 8MzK7/0pNVwfiThV9zeKiwmhywvpMRr/LhlcOXHhvpynCgbWJme3kuZOX956rEnP
# LqR0kq3bPKSchh/jwVYbKyP/j7XqiHtwa+aguv06P0WmxOgWkVKLQcBIhEuWTatE
# QOON8BUozu3xGFYHKi8QxAwIZDwzj64ojDzLj4gLDb879M4ee47vtevLt/B3E+bn
# KD+sEq6lLyJsQfmCXBVmzGwOysWGw/YmMwwHS6DTBwJqakAwSEs0qFEgu60bhQji
# WQ1tygVQK+pKHJ6l/aCnHwZ05/LWUpD9r4VIIflXO7ScA+2GRfS0YW6/aOImYIbq
# yK+p/pQd52MbOoZWeE4wggc/MIIFJ6ADAgECAhAGIHwU0816HPO5/cZvlRISMA0G
# CSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwHhcNMjUwNzAyMDAwMDAwWhcNMjgwNzAx
# MjM1OTU5WjCBxzETMBEGCysGAQQBgjc8AgEDEwJVUzEZMBcGCysGAQQBgjc8AgEC
# EwhEZWxhd2FyZTEdMBsGA1UEDwwUUHJpdmF0ZSBPcmdhbml6YXRpb24xEDAOBgNV
# BAUTBzU3NDQ1NDQxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlhMRYw
# FAYDVQQHEw1TYW4gRnJhbmNpc2NvMRQwEgYDVQQKEwtUcmliZVZSIEluYzEUMBIG
# A1UEAxMLVHJpYmVWUiBJbmMwggGiMA0GCSqGSIb3DQEBAQUAA4IBjwAwggGKAoIB
# gQDFleYblLmsUTl8DL8MPV9qwwYyuvqgWwu7H5rzm5QHGFa9Iu24qrJ8vZUz1qy9
# Rkd4eSqxuUUH3O2pR4bZLze00avj+kbLVprNSjsd+GjalLyPBlH/Mgrg5HXb713/
# TL8YhiiGyQTb7xo6G/+PHeo/Lqv8zyDMQyMNvGhk0H3nH1CTYvQOV/iApjlfUYI5
# wc7I0E3CJP4mlM8we+RI9oPOqr0hgmIDvmG7w6xDQ55ikF1Qn3cBTbhMbNYA6V3l
# Dqajh1b8vajqWrY2MxVeLAR31yo++7//PaZCJmyveIBXYMp7P5DlyfF3LAjAsxq0
# Q/9ximGHDy6bH1Qu6lhgfpT7dK1sOh5h1dqeac/5QHPz2NAx7Pm0kFbekzlMCGJB
# afZC/o8taW0p7p6RJudGjpBbQH6Gg8ZZWqe9cI03PHva9Gp17+zvPDQZickqGC9L
# PQoLTj/mW/wu0oho+3GTwF7ERCdXrA4k0Vjqok5MXRBjxI15gYPlB8L4dzzLCy7U
# DEkCAwEAAaOCAgIwggH+MB8GA1UdIwQYMBaAFGg34Ou2O/hfEYb7/mF7CIhl9E5C
# MB0GA1UdDgQWBBQQFKtT2BNRbcQLbkqwqLkxwP+bfTA9BgNVHSAENjA0MDIGBWeB
# DAEDMCkwJwYIKwYBBQUHAgEWG2h0dHA6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwgbUGA1UdHwSBrTCB
# qjBToFGgT4ZNaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3Rl
# ZEc0Q29kZVNpZ25pbmdSU0E0MDk2U0hBMzg0MjAyMUNBMS5jcmwwU6BRoE+GTWh0
# dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNENvZGVTaWdu
# aW5nUlNBNDA5NlNIQTM4NDIwMjFDQTEuY3JsMIGUBggrBgEFBQcBAQSBhzCBhDAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMFwGCCsGAQUFBzAC
# hlBodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRD
# b2RlU2lnbmluZ1JTQTQwOTZTSEEzODQyMDIxQ0ExLmNydDAJBgNVHRMEAjAAMA0G
# CSqGSIb3DQEBCwUAA4ICAQB63u0SCSWjXLD+VMsubxnqiJXzxB5QA+LoQBf2/1I9
# YMMWWJmAbXphMwPJ2uGTOhB/pJG2pJxqAFqqEiYn6j34bbKPLds9iX7qK27aOiY7
# PDY2RrwJkbccM7zgVxoWUhSbsgLuSl5Yxrk+JBDJpt1wUcA34cV1F3EV0ZTXSCY6
# iyWpdFX8KM6NHg3OG/h78XFGqbgy6s8idB7W5HtxfMIeHIc3Jop/0ahugbDUsCXy
# TDnsn5tmDbanhUpS3ct8NkQSpXnGswFOblyOQu4vj3yfimdhJGskBlf/BviyvWpD
# r67OpN+D8/k7UIAqFqHzuh7Z1l+OXLokuQALXuvSWcDqeewuJQQVIVq3PALnMSmi
# Nk+cPHFetqA1H7m7rJgF4WxemoElVO8I2f+FFpsfhC6GHz6UR2QQC2N7Jb9iUkeo
# lKyQnmqn7J0B7LFhxHeMivCYmF6GsES5l2bnty36oBAPSdULVkjuBvSqUKgyS2Aw
# W9Gtgu8MD/ZQ1SN6W/RAkACuTn3pego6jiYCbR62x+agdDYG+lZQISGPcw+EcyCe
# PkB4ZvljdCB6T8vcf20aY9OMGaq8sFCdEL1/vsHdNb/n0rJ0vRpQHIBrsqBsoP+W
# 6QUMr0o78gueK4z4L/mGdLKtsfRlfm+HJ06+EuMuvItmhxWtliiAupSOik8qHOdF
# JjGCGiEwghodAgEBMH0waTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0
# LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IENvZGUgU2lnbmlu
# ZyBSU0E0MDk2IFNIQTM4NCAyMDIxIENBMQIQBiB8FNPNehzzuf3Gb5USEjANBglg
# hkgBZQMEAgEFAKB8MBAGCisGAQQBgjcCAQwxAjAAMBkGCSqGSIb3DQEJAzEMBgor
# BgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3
# DQEJBDEiBCBQa7n65Zt8jOE2UGrbB3JXRvE1GxcpMNDxNW99FUi8HjANBgkqhkiG
# 9w0BAQEFAASCAYBOIf4NVgPqftTXGWbsWaiW5peih64KuxNr/AIXfoX6phavzN8c
# gOCt+Gu6Kd97DCcbYtMXrj4bp4Psek0bQ5h3DqGc9LfTkE0JRsQdZ9lUTbYe93H+
# jwNd5tmFRboNqUsKUlqc03/xM8mBhWpmvOyNRpGvfu3egyga/YepM8B/e1H+07eE
# OhjCrfKuoF3DSnk+2Ma7GcTUkyur5EPhByMUqs1pzDG7D1ir5zUE/WEJ1iThrxaj
# MDwOD6Qvt1+FGF8hBP6UU1dstzX+vG/Hc61O8Lk9FQO1XWuCHuVRlijsG5vg+vNd
# o/OWRTTa7oGk0bwrjllQxBHoTIRUtz3ahGhLP3H1FOS9nn/MYA/BuJeCecugSfNH
# 3QrfIuqWe9XHSuIf5U/RCxvJCCGK4EdZqtDF334pa3dogKsMTGwI47C+A+LEkByR
# T/5TNsXrcvZ4lh5uF+pXuJ/Ubrf5MUzZ1lk6OYygAX7OYw7xOlmho2qKcbW+iq7G
# hMnvkJjrEFwEIPqhghd3MIIXcwYKKwYBBAGCNwMDATGCF2MwghdfBgkqhkiG9w0B
# BwKgghdQMIIXTAIBAzEPMA0GCWCGSAFlAwQCAQUAMHgGCyqGSIb3DQEJEAEEoGkE
# ZzBlAgEBBglghkgBhv1sBwEwMTANBglghkgBZQMEAgEFAAQgoJK6DYeSFXLFIU+v
# m9xPiHDAt/3uUkR8/OD4uyVTEgYCEQCz5zfRRZ5Kp/SfXMbAlpbRGA8yMDI2MTAz
# MDA5MDgyOVqgghM6MIIG7TCCBNWgAwIBAgIQCE/cM09+RU7bww+P+ZIYNTANBgkq
# hkiG9w0BAQsFADBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIElu
# Yy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgVGltZVN0YW1waW5nIFJT
# QTQwOTYgU0hBMjU2IDIwMjUgQ0ExMB4XDTI2MDgwNTAwMDAwMFoXDTM3MTEwNDIz
# NTk1OVowYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTsw
# OQYDVQQDEzJEaWdpQ2VydCBTSEEyNTYgUlNBNDA5NiBUaW1lc3RhbXAgUmVzcG9u
# ZGVyIDIwMjYgMTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALZ7pvLJ
# /s1K+NSbTGWz/TjGMPh8CQ6RucZCLv5anHzWJjF/NWJrFIhy24fcpKXlgRiky4WA
# awDfU3YP0BMxt9l3Dm5oCG5Z69AqEN1kgHg2epx+l+lZBcmJCcN0ASURML5uFIS8
# 0sZsDwO3BSkUxDjLJhBI+qiZP3aixAC/qEGLjsBNlLol9VZ7pfGEXiMlneJIC5/Y
# KuizVzNFKZZEeoy/0B8Zm+nzKBgSWG52lCO1w+nCg6XpCtklTJXeIg283hw7Tmms
# ZXR+SMbjbrEOvZ3fP2VxIgeR28Y90ZStd3F9VuA5RVynb/whITPAo9b75Zr4Ta6M
# j3URm26QZYMn/FnbuTegcoRcFEZ9FOqM5T6MTdtr/n74lIT/ug0eeOzmZ6QTFg33
# otX+bFRsIolvykE1jive4PuESaT8zzVeFWDAMDtozNgLctkGD1ZjkEyZtJrLl5ya
# 0m5doH/ScpaZCZVl6pNUOCybMc/kxC6EAmSJY24L0yYKD1Nkddsnb/ItVKi/2nXp
# QNMu1PT5prW83vV8d67WowuUs0HdY4H8AMLGvdL/WHEj3ZnqMqAQQP9u3Ai9t+5e
# Q02GDwy0ODjdzi0xlp70W+ow63/0++YDEX1M0iwgUHwbrJvfpklkZQvw3+kv3vUP
# Itdwroczk9icflf55W1zOEKAcJVAIXpcMCU9AgMBAAGjggGVMIIBkTAMBgNVHRMB
# Af8EAjAAMB0GA1UdDgQWBBQUyWOKMC7USvtulPPm40B+9ezN4jAfBgNVHSMEGDAW
# gBTvb1NK6eQGfHrK4pBW9i/USezLTjAOBgNVHQ8BAf8EBAMCB4AwFgYDVR0lAQH/
# BAwwCgYIKwYBBQUHAwgwgZUGCCsGAQUFBwEBBIGIMIGFMCQGCCsGAQUFBzABhhho
# dHRwOi8vb2NzcC5kaWdpY2VydC5jb20wXQYIKwYBBQUHMAKGUWh0dHA6Ly9jYWNl
# cnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFRpbWVTdGFtcGluZ1JT
# QTQwOTZTSEEyNTYyMDI1Q0ExLmNydDBfBgNVHR8EWDBWMFSgUqBQhk5odHRwOi8v
# Y3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRUaW1lU3RhbXBpbmdS
# U0E0MDk2U0hBMjU2MjAyNUNBMS5jcmwwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJ
# YIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQCNxTphHp1SCt+ZrAmAfn0oQLFr
# 0mLywSLaDXQIENoyKqxrFbJblzCVP/pkXmwXOdrOpWygLzlT12os5ipDCy35RBCg
# 2UMeApEtrfGhz45F4Wt4WGdNdIbRWt3YTYJmpR+b7lr4d7Uwn+H600u4D7RnOGf8
# Wj4UNgAdZkfHhHv1mx9EVh71SJelcEN/oORSjXzdjfw1iZH9d8Nh/thn6hH23d+V
# sPAr6GAYyzSA02nXD1nYLI7Ijmiv+xLCiYC41DSFYL3GhTiy0PxpawPtGRyaBVGz
# q+UiTfM8pD7KVyF5aQyWP4KhVGUUTnmm/RlYJoW3TiXA/+t0YcT2oRVBm3JETjaj
# Hug2AL+v5jhtKVnd3D0rbHXEu27o+Q8p4sEWPMqKDB+qbceb6T/6WcwTwXmQ9lOC
# LLYcsQeSWmvKqzpAec9etE14jOQAzLKWdE3w/TCaKtLRaRT7LCkRYVnhA2D73FLj
# e1O5b3HR5eHs0NzU/+xX7NbEdcofy0W3Wdwd1XOqtlpg/JgwtKfZM5dqO94lbUve
# OiJBI+xZEbGRsMNbXmMREUTgu+Oca7Y73MPWcslIx2VhkSKSXjDbD6rgg39H5Mh7
# QfieAIjWagkJNt68Yfim6cjEzVSiLSeZfdkr5dtFPTW6jATlWJdYeeDRGCyatf8R
# 1hSjzSvdN8yWQPT9gzCCBrQwggScoAMCAQICEA3HrFcF/yGZLkBDIgw6SYYwDQYJ
# KoZIhvcNAQELBQAwYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IElu
# YzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQg
# VHJ1c3RlZCBSb290IEc0MB4XDTI1MDUwNzAwMDAwMFoXDTM4MDExNDIzNTk1OVow
# aTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMUEwPwYDVQQD
# EzhEaWdpQ2VydCBUcnVzdGVkIEc0IFRpbWVTdGFtcGluZyBSU0E0MDk2IFNIQTI1
# NiAyMDI1IENBMTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALR4MdMK
# mEFyvjxGwBysddujRmh0tFEXnU2tjQ2UtZmWgyxU7UNqEY81FzJsQqr5G7A6c+Gh
# /qm8Xi4aPCOo2N8S9SLrC6Kbltqn7SWCWgzbNfiR+2fkHUiljNOqnIVD/gG3SYDE
# Ad4dg2dDGpeZGKe+42DFUF0mR/vtLa4+gKPsYfwEu7EEbkC9+0F2w4QJLVSTEG8y
# AR2CQWIM1iI5PHg62IVwxKSpO0XaF9DPfNBKS7Zazch8NF5vp7eaZ2CVNxpqumzT
# CNSOxm+SAWSuIr21Qomb+zzQWKhxKTVVgtmUPAW35xUUFREmDrMxSNlr/NsJyUXz
# dtFUUt4aS4CEeIY8y9IaaGBpPNXKFifinT7zL2gdFpBP9qh8SdLnEut/GcalNeJQ
# 55IuwnKCgs+nrpuQNfVmUB5KlCX3ZA4x5HHKS+rqBvKWxdCyQEEGcbLe1b8Aw4wJ
# khU1JrPsFfxW1gaou30yZ46t4Y9F20HHfIY4/6vHespYMQmUiote8ladjS/nJ0+k
# 6MvqzfpzPDOy5y6gqztiT96Fv/9bH7mQyogxG9QEPHrPV6/7umw052AkyiLA6tQb
# Zl1KhBtTasySkuJDpsZGKdlsjg4u70EwgWbVRSX1Wd4+zoFpp4Ra+MlKM2baoD6x
# 0VR4RjSpWM8o5a6D8bpfm4CLKczsG7ZrIGNTAgMBAAGjggFdMIIBWTASBgNVHRMB
# Af8ECDAGAQH/AgEAMB0GA1UdDgQWBBTvb1NK6eQGfHrK4pBW9i/USezLTjAfBgNV
# HSMEGDAWgBTs1+OC0nFdZEzfLmc/57qYrhwPTzAOBgNVHQ8BAf8EBAMCAYYwEwYD
# VR0lBAwwCgYIKwYBBQUHAwgwdwYIKwYBBQUHAQEEazBpMCQGCCsGAQUFBzABhhho
# dHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQQYIKwYBBQUHMAKGNWh0dHA6Ly9jYWNl
# cnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3J0MEMGA1Ud
# HwQ8MDowOKA2oDSGMmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRy
# dXN0ZWRSb290RzQuY3JsMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwH
# ATANBgkqhkiG9w0BAQsFAAOCAgEAF877FoAc/gc9EXZxML2+C8i1NKZ/zdCHxYga
# MH9Pw5tcBnPw6O6FTGNpoV2V4wzSUGvI9NAzaoQk97frPBtIj+ZLzdp+yXdhOP4h
# CFATuNT+ReOPK0mCefSG+tXqGpYZ3essBS3q8nL2UwM+NMvEuBd/2vmdYxDCvwzJ
# v2sRUoKEfJ+nN57mQfQXwcAEGCvRR2qKtntujB71WPYAgwPyWLKu6RnaID/B0ba2
# H3LUiwDRAXx1Neq9ydOal95CHfmTnM4I+ZI2rVQfjXQA1WSjjf4J2a7jLzWGNqNX
# +DF0SQzHU0pTi4dBwp9nEC8EAqoxW6q17r0z0noDjs6+BFo+z7bKSBwZXTRNivYu
# ve3L2oiKNqetRHdqfMTCW/NmKLJ9M+MtucVGyOxiDf06VXxyKkOirv6o02OoXN4b
# FzK0vlNMsvhlqgF2puE6FndlENSmE+9JGYxOGLS/D284NHNboDGcmWXfwXRy4kbu
# 4QFhOm0xJuF2EZAOk5eCkhSxZON3rGlHqhpB/8MluDezooIs8CVnrpHMiD2wL40m
# m53+/j7tFaxYKIqL0Q4ssd8xHZnIn/7GELH3IdvG2XlM9q7WP/UwgOkw/HQtyRN6
# 2JK4S1C8uw3PdBunvAZapsiI5YKdvlarEvf8EA+8hcpSM9LHJmyrxaFtoza2zNaQ
# 9k+5t1wwggWNMIIEdaADAgECAhAOmxiO+dAt5+/bUOIIQBhaMA0GCSqGSIb3DQEB
# DAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNV
# BAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQg
# SUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBaFw0zMTExMDkyMzU5NTlaMGIxCzAJ
# BgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5k
# aWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAL/mkHNo3rvkXUo8MCIwaTPs
# wqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3EMB/zG6Q4FutWxpdtHauyefLKEdLk
# X9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKyunWZanMylNEQRBAu34LzB4TmdDtt
# ceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsFxl7sWxq868nPzaw0QF+xembud8hI
# qGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU15zHL2pNe3I6PgNq2kZhAkHnDeMe2
# scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJBMtfbBHMqbpEBfCFM1LyuGwN1XXhm
# 2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObURWBf3JFxGj2T3wWmIdph2PVldQnaH
# iZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6nj3cAORFJYm2mkQZK37AlLTSYW3r
# M9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxBYKqxYxhElRp2Yn72gLD76GSmM9GJ
# B+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5SUUd0viastkF13nqsX40/ybzTQRES
# W+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+xq4aLT8LWRV+dIPyhHsXAj6Kxfgom
# mfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIBNjAPBgNVHRMBAf8EBTADAQH/MB0G
# A1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwPTzAfBgNVHSMEGDAWgBRF66Kv9JLL
# gjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMCAYYweQYIKwYBBQUHAQEEbTBrMCQG
# CCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKG
# N2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJv
# b3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDARBgNVHSAECjAIMAYGBFUd
# IAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0NcVec4X6CjdBs9thbX979XB72arKGH
# LOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnovLbc47/T/gLn4offyct4kvFIDyE7Q
# Kt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65ZyoUi0mcudT6cGAxN3J0TU53/oWajw
# vy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFWjuyk1T3osdz9HNj0d1pcVIxv76FQ
# Pfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPFmCLBsln1VWvPJ6tsds5vIy30fnFq
# I2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9ztwGpn1eqXijiuZQxggN8MIIDeAIB
# ATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8G
# A1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBT
# SEEyNTYgMjAyNSBDQTECEAhP3DNPfkVO28MPj/mSGDUwDQYJYIZIAWUDBAIBBQCg
# gdEwGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMBwGCSqGSIb3DQEJBTEPFw0y
# NjEwMzAwOTA4MjlaMCsGCyqGSIb3DQEJEAIMMRwwGjAYMBYEFFHZq9oDSXPYT0Jm
# rKSCSOazacQ5MC8GCSqGSIb3DQEJBDEiBCCmD7fMOlM5WR+hZlr7dab6o3yyK4/m
# pWOCU1q2xG+H5jA3BgsqhkiG9w0BCRACLzEoMCYwJDAiBCAtoJ2n9BMfn+cttsXm
# 6cllZ1WvBD8ep0LMDSEg4UHr/DANBgkqhkiG9w0BAQEFAASCAgAeHmVMnpjgsWux
# 8oc3rmslgWUQovhFFPLaQcmJY2bVr56l+wdQpURYsu4UxszZEo/ecw/y6aKPE8DS
# 8Qd7gf0BW69Gu2I+foIsARshwioz2oh6ODtv4dZU2+v/vpJ6FxuK5ja2riEXjJE9
# g2WCCLNJaanoVLrHQcPPg+ax49kjNlqbnwHoOxu02exldOQ9NbdsSgNWFWCFZd+8
# llsSpX/3IuELQBqvnE2po95619p+37hgfYvDHI6QiR1LdvqmKWNP2TujAhOfqdzr
# 6iO9qg45XwBe1FlqUamarEPbGRk74/9l+jgbaw9PHkTCx0BaDdhoGFX4IDtW38RB
# GOfziPiGospEpnk4lqJYa9yaCYGW/epwwzjE04vC6vpWPg9hdPHfZJbgRM/B8kS9
# Pq9SSJAdMfy2kY0UbEctCNne/cnulDpG9Gf4vZg22nwYb9gL6nJNbzaSByYHKpZZ
# vtUB5RkUlzvhoXIOUoSYKhnA/uYySyzd14LPuTgl2guR6CZZ26TOvF/B7BALlMtP
# a2//gl5G+gBSLxmTwymVApGDiIaXlG4lBdupGToM4Wq/PMfQn+OSrBGHZHWuYjBf
# kQ9PJG33ZVWXE988lx1wiQhumCaecYbBrURKnAnQRHuXiSKUlhJmy+PMFtbSJRtd
# w1daJE2Tbe/OhzdgEeP6zt5lD0dclQ==
# SIG # End signature block
