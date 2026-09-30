# Windows Feature Version Manager
# Portable utility for inspecting and managing the Windows Target Feature Update policy.
# Run elevated. The companion CMD launcher will request elevation automatically.
# Version 1.0.1

$ErrorActionPreference = 'Stop'
$PolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'

function Write-Rule {
    Write-Host ('-' * 64) -ForegroundColor DarkGray
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Restart-Elevated {
    if (Test-IsAdministrator) { return }

    Write-Host 'Administrator rights are required. Requesting elevation...' -ForegroundColor Yellow

    $argList = @(
        '-NoProfile'
        '-ExecutionPolicy', 'Bypass'
        '-File', ('"{0}"' -f $PSCommandPath)
    )

    try {
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $argList
    }
    catch {
        Write-Host "Elevation was cancelled or failed: $($_.Exception.Message)" -ForegroundColor Red
        Read-Host 'Press Enter to exit'
    }
    exit
}

function Get-WindowsInfo {
    $cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'

    $caption = try {
        (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).Caption
    } catch {
        $cv.ProductName
    }

    [pscustomobject]@{
        ComputerName   = $env:COMPUTERNAME
        Caption        = $caption
        EditionID      = $cv.EditionID
        DisplayVersion = $cv.DisplayVersion
        CurrentBuild   = $cv.CurrentBuild
        UBR            = $cv.UBR
        Build          = if ($null -ne $cv.UBR) { "$($cv.CurrentBuild).$($cv.UBR)" } else { "$($cv.CurrentBuild)" }
        IsWindows11    = ([int]$cv.CurrentBuild -ge 22000)
        IsHome         = ($cv.EditionID -match 'Core|Home')
    }
}

function Get-TargetPolicy {
    $exists = Test-Path $PolicyPath
    $product = $null
    $enabled = $null
    $target = $null

    if ($exists) {
        $p = Get-ItemProperty -Path $PolicyPath -ErrorAction SilentlyContinue
        $product = $p.ProductVersion
        $enabled = $p.TargetReleaseVersion
        $target = $p.TargetReleaseVersionInfo
    }

    $present = @()
    if ($null -ne $product) { $present += 'ProductVersion' }
    if ($null -ne $enabled) { $present += 'TargetReleaseVersion' }
    if ($null -ne $target)  { $present += 'TargetReleaseVersionInfo' }

    if ($present.Count -eq 0) {
        $status = 'NOT CONFIGURED'
    }
    elseif (($enabled -eq 1) -and $product -and $target) {
        $status = 'CONFIGURED'
    }
    else {
        $status = 'INCOMPLETE / CUSTOM'
    }

    [pscustomobject]@{
        Status  = $status
        Product = $product
        Enabled = $enabled
        Target  = $target
        Present = $present
    }
}

function Format-PolicyValue($Value) {
    if ($null -eq $Value -or "$Value" -eq '') { return '<Microsoft default>' }
    return "$Value"
}

function Show-Status {
    Clear-Host
    $win = Get-WindowsInfo
    $pol = Get-TargetPolicy

    Write-Host '================================================================' -ForegroundColor Cyan
    Write-Host ' Windows Feature Version Manager' -ForegroundColor Cyan
    Write-Host '================================================================' -ForegroundColor Cyan
    Write-Host
    Write-Host (' Computer            : {0}' -f $win.ComputerName)
    Write-Host (' Windows             : {0}' -f $win.Caption)
    Write-Host (' Edition ID          : {0}' -f $win.EditionID)
    Write-Host (' Installed Version   : {0}' -f (Format-PolicyValue $win.DisplayVersion))
    Write-Host (' OS Build            : {0}' -f $win.Build)
    Write-Host

    Write-Host ' FEATURE UPDATE POLICY' -ForegroundColor Cyan
    Write-Rule

    $statusColor = switch ($pol.Status) {
        'CONFIGURED'        { 'Green' }
        'NOT CONFIGURED'    { 'Gray' }
        default             { 'Yellow' }
    }

    Write-Host ' Status               : ' -NoNewline
    Write-Host $pol.Status -ForegroundColor $statusColor
    Write-Host (' Target Product       : {0}' -f (Format-PolicyValue $pol.Product))
    Write-Host (' Target Version       : {0}' -f (Format-PolicyValue $pol.Target))
    Write-Host (' Target Policy Flag   : {0}' -f (Format-PolicyValue $pol.Enabled))

    Write-Host
    if ($pol.Status -eq 'NOT CONFIGURED') {
        Write-Host " Windows Update is not pinned to a target feature release by" -ForegroundColor Gray
        Write-Host " these policy values." -ForegroundColor Gray
    }
    elseif ($pol.Status -eq 'CONFIGURED') {
        Write-Host (" Windows Update target: {0} {1}" -f $pol.Product, $pol.Target) -ForegroundColor Green
    }
    else {
        Write-Host ' WARNING: One or more target-release policy values exist, but' -ForegroundColor Yellow
        Write-Host ' they do not form the normal complete configuration.' -ForegroundColor Yellow
    }

    if (-not $win.IsWindows11) {
         Write-Host
         Write-Host '  UNSUPPORTED OPERATING SYSTEM' -ForegroundColor Red
         Write-Host
         Write-Host '  Windows Feature Version Manager is designed for Windows 11.' -ForegroundColor Yellow
         Write-Host '  Windows 10 is not a supported or tested target for this utility.' -ForegroundColor Yellow
         Write-Host
         Write-Host '  No changes have been made.' -ForegroundColor Gray
         Write-Host
         Read-Host 'Press Enter to exit' | Out-Null
         exit 1
    }

    if ($win.IsHome) {
        Write-Host
        Write-Host ' NOTE: Windows Home detected.' -ForegroundColor Yellow
        Write-Host ' Home does not include Local Group Policy Editor and Microsoft' -ForegroundColor Yellow
        Write-Host ' does not document this Windows Update policy as applicable to' -ForegroundColor Yellow
        Write-Host ' Home. Registry settings can be inspected/managed here, but the' -ForegroundColor Yellow
        Write-Host ' OS may not honor them with managed-edition policy semantics.' -ForegroundColor Yellow
    }
	
    Write-Host
    Write-Rule
    Write-Host ' [1] Set / Change Target Feature Version'
    Write-Host ' [2] Remove Target Feature Version Policy (MS Defaults)'
    Write-Host ' [3] Refresh / Show Detailed Status'
    Write-Host ' [Q] Quit'
    Write-Rule

    return [pscustomobject]@{ Windows = $win; Policy = $pol }
}

function Test-VersionInput([string]$Version) {
    # Intentionally permissive enough for future Windows naming changes.
    # Normal modern Windows feature releases look like 24H2, 25H2, 26H2, etc.
    return ($Version -match '^\d{2}H[1-2]$')
}

function Set-TargetVersion {
	Write-Host
    Write-Host '  IMPORTANT:' -ForegroundColor Yellow
    Write-Host '  If Windows Update already shows a newer Feature Update as'
    Write-Host '  "Pending restart", setting a Target Feature Version does not'
    Write-Host '  guarantee that the staged update will be cancelled.'
    Write-Host
    Write-Host '  Review Windows Update before rebooting.' -ForegroundColor Yellow
    Write-Host
    $before = Get-TargetPolicy
    $win = Get-WindowsInfo

    Write-Host
    $defaultPrompt = if ($before.Target) { $before.Target } else { '<Microsoft default>' }
    $target = Read-Host "Enter target feature version (example: 25H2) [current: $defaultPrompt]"
    $target = $target.Trim().ToUpperInvariant()

    if ([string]::IsNullOrWhiteSpace($target)) {
        Write-Host 'No version entered. No changes made.' -ForegroundColor Yellow
        return
    }

    if (-not (Test-VersionInput $target)) {
        Write-Host
        Write-Host "'$target' does not match the usual Windows feature-release format (example: 25H2)." -ForegroundColor Yellow
        $continue = Read-Host 'Use it anyway? [Y/N]'
        if ($continue -notmatch '^[Yy]$') {
            Write-Host 'No changes made.' -ForegroundColor Yellow
            return
        }
    }

    Write-Host
    Write-Host 'PROPOSED CHANGE' -ForegroundColor Cyan
    Write-Rule
    Write-Host (' Target Product : {0}  ->  Windows 11' -f (Format-PolicyValue $before.Product))
    Write-Host (' Target Version : {0}  ->  {1}' -f (Format-PolicyValue $before.Target), $target)
    Write-Host (' Policy Status  : {0}  ->  CONFIGURED' -f $before.Status)

    if ($win.IsHome) {
        Write-Host
        Write-Host ' Windows Home: this writes the corresponding registry policy' -ForegroundColor Yellow
        Write-Host ' values, but Microsoft does not list this policy as applicable' -ForegroundColor Yellow
        Write-Host ' to Home editions.' -ForegroundColor Yellow
    }

    Write-Host
    $confirm = Read-Host 'Apply this change? [Y/N]'
    if ($confirm -notmatch '^[Yy]$') {
        Write-Host 'No changes made.' -ForegroundColor Yellow
        return
    }

    try {
        New-Item -Path $PolicyPath -Force | Out-Null
        New-ItemProperty -Path $PolicyPath -Name 'ProductVersion' -PropertyType String -Value 'Windows 11' -Force | Out-Null
        New-ItemProperty -Path $PolicyPath -Name 'TargetReleaseVersion' -PropertyType DWord -Value 1 -Force | Out-Null
        New-ItemProperty -Path $PolicyPath -Name 'TargetReleaseVersionInfo' -PropertyType String -Value $target -Force | Out-Null

        $after = Get-TargetPolicy
        if (($after.Status -eq 'CONFIGURED') -and
            ($after.Product -eq 'Windows 11') -and
            ($after.Enabled -eq 1) -and
            ($after.Target -eq $target)) {
            Write-Host
            Write-Host "SUCCESS: Target Feature Version is now Windows 11 $target." -ForegroundColor Green
            Write-Host 'Normal quality/security update policy was not changed.' -ForegroundColor Green
        }
        else {
            throw 'Post-change verification did not match the requested configuration.'
        }
    }
    catch {
        Write-Host
        Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host
    Read-Host 'Press Enter to continue'
}

function Remove-TargetPolicy {
    $before = Get-TargetPolicy

    Write-Host
    Write-Host 'RESET TARGET FEATURE VERSION POLICY' -ForegroundColor Cyan
    Write-Rule
    Write-Host (' Current Status        : {0}' -f $before.Status)
    Write-Host (' ProductVersion        : {0}' -f (Format-PolicyValue $before.Product))
    Write-Host (' TargetReleaseVersion  : {0}' -f (Format-PolicyValue $before.Enabled))
    Write-Host (' Target Version        : {0}' -f (Format-PolicyValue $before.Target))
    Write-Host

    if ($before.Status -eq 'NOT CONFIGURED') {
        Write-Host 'Nothing to remove. These target-version values are already not configured.' -ForegroundColor Gray
        Write-Host
        Read-Host 'Press Enter to continue'
        return
    }

    Write-Host 'This removes ONLY these Target Feature Version values:' -ForegroundColor Yellow
    Write-Host '  ProductVersion'
    Write-Host '  TargetReleaseVersion'
    Write-Host '  TargetReleaseVersionInfo'
    Write-Host
    Write-Host 'Other Windows Update policies will NOT be modified.' -ForegroundColor Yellow
    Write-Host
    $confirm = Read-Host 'Return Target Feature Version policy to Not Configured? [Y/N]'
    if ($confirm -notmatch '^[Yy]$') {
        Write-Host 'No changes made.' -ForegroundColor Yellow
        return
    }

    try {
        if (Test-Path $PolicyPath) {
            foreach ($name in 'ProductVersion','TargetReleaseVersion','TargetReleaseVersionInfo') {
                Remove-ItemProperty -Path $PolicyPath -Name $name -ErrorAction SilentlyContinue
            }
        }

        $after = Get-TargetPolicy
        if ($after.Present.Count -eq 0) {
            Write-Host
            Write-Host 'SUCCESS: Target Feature Version policy is NOT CONFIGURED.' -ForegroundColor Green
            Write-Host 'Windows feature-update selection is no longer pinned by these values.' -ForegroundColor Green
            Write-Host 'No other Windows Update policy values were changed.' -ForegroundColor Green
        }
        else {
            throw 'One or more target-version values remained after reset.'
        }
    }
    catch {
        Write-Host
        Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host
    Read-Host 'Press Enter to continue'
}

Restart-Elevated

do {
    $state = Show-Status
    $choice = Read-Host 'Selection'

    switch ($choice.ToUpperInvariant()) {
        '1' { Set-TargetVersion }
        '2' { Remove-TargetPolicy }
        '3' { continue }
        'Q' { exit 0 }
        default {
            Write-Host
            Write-Host 'Invalid selection.' -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
    }
} while ($true)
