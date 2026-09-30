# Windows Feature Version Manager

**Windows Feature Version Manager** is a simple utility for viewing and setting the Windows 11 Target Feature Update policy, providing a quick way to keep Windows on the feature version you're comfortable with until you're ready to move to a newer release.

For example, if your computer is running Windows 11 25H2 and you aren't ready to move to 26H2, you can set the target feature version to `25H2`. When you're ready to upgrade later, simply change the target version or remove the policy and return it to Microsoft's default behavior.

> **This is a target-version policy tool, not a Windows Update disabling tool.**
>
> Windows Update continues to operate normally for applicable security, quality, Defender, .NET, and other updates. The utility only configures the Windows Target Feature Update policy that tells Windows Update which Windows feature release the computer should remain on.

## Features

- View the installed Windows version and current Target Feature Update policy
- Set or change the target Windows 11 feature version
- Remove the Target Feature Update policy and return it to **Not Configured**
- Detect incomplete or custom Target Feature Update configurations
- Windows 11 operating system check before allowing policy changes
- Automatic elevation through UAC
- Portable — no installation or additional PowerShell modules required

## Quick Start

Keep these two files together in the same folder:

- `Windows-Feature-Version-Manager.ps1`
- `Run Windows Feature Version Manager.cmd`

Then:

1. Double-click **Run Windows Feature Version Manager.cmd** normally.
2. Approve the Windows UAC prompt when requested.
3. Review the currently installed Windows version and existing policy status.
4. Select the desired action from the menu.

You do **not** need to right-click the CMD file and select **Run as administrator**. The PowerShell script detects when it is not running as administrator and relaunches itself with elevation.

The CMD launcher is the recommended entry point. It starts PowerShell with a process-only execution-policy bypass so locally downloaded scripts can run without permanently changing the system's PowerShell execution policy.

## Main Menu

```text
[1] Set / Change Target Feature Version
[2] Remove Target Feature Version Policy (MS Defaults)
[3] Refresh / Show Detailed Status
[Q] Quit
```

### Set / Change Target Feature Version

Select option `1` and enter the desired Windows 11 feature release, for example:

```text
25H2
```

The utility displays the proposed change and asks for confirmation before modifying the policy.

Normal version input uses Microsoft's familiar feature-release format, such as `25H2` or `26H2`.

### Remove Target Feature Version Policy

Option `2` removes only the Target Feature Update policy values managed by this utility.

This returns this particular policy to **Not Configured / Microsoft default**.

It does **not** reset all Windows Update settings or policies.

### Refresh / Show Detailed Status

Option `3` performs a read-only refresh and displays the currently installed Windows version and Target Feature Update policy state.

## Exactly What This Tool Changes

Windows Feature Version Manager uses the Windows Update policy registry location:

```text
HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate
```

When a target feature version is configured, the utility manages these three values:

```text
ProductVersion           REG_SZ      Windows 11
TargetReleaseVersion     REG_DWORD   1
TargetReleaseVersionInfo REG_SZ      <selected version>
```

For example, targeting Windows 11 25H2 results in:

```text
ProductVersion           = Windows 11
TargetReleaseVersion     = 1
TargetReleaseVersionInfo = 25H2
```

When **Remove Target Feature Version Policy (MS Defaults)** is selected, the utility removes **only**:

```text
ProductVersion
TargetReleaseVersion
TargetReleaseVersionInfo
```

It does **not** delete the `WindowsUpdate` policy key itself and does **not** remove unrelated Windows Update policies that may already exist on the computer.

## Equivalent Group Policy Setting

On supported Windows editions, these values correspond to Microsoft's **Select the target Feature Update version** policy:

**Computer Configuration → Administrative Templates → Windows Components → Windows Update → Manage updates offered from Windows Update → Select the target Feature Update version**

For example:

```text
Product Version: Windows 11
Target Version:  25H2
```

Windows Feature Version Manager provides a small interface for inspecting and managing this specific policy without having to navigate Local Group Policy Editor or manually edit the registry.

## What This Tool Does NOT Change

Windows Feature Version Manager does **not**:

- Disable Windows Update
- Disable Windows Update services
- Disable Windows Update Medic Service
- Disable or modify Windows Update scheduled tasks
- Clear or rename `SoftwareDistribution`
- Remove installed or staged Windows update packages
- Configure Windows Update pause dates
- Configure feature or quality update deferral periods
- Disable security or quality updates
- Disable Microsoft Defender updates
- Permanently change the PowerShell execution policy
- Delete unrelated Windows Update policy settings

Its scope is deliberately limited to the three Target Feature Update policy values documented above.

## Important: Feature Update Already Pending Restart

If Windows Update has already staged a newer Feature Update and shows it as **Pending restart**, setting a Target Feature Version afterward does **not** guarantee that the staged update will be cancelled.

The utility therefore displays this warning before setting or changing a target:

```text
IMPORTANT:
If Windows Update already shows a newer Feature Update as
"Pending restart", setting a Target Feature Version does not
guarantee that the staged update will be cancelled.

Review Windows Update before rebooting.
```

This can occur when a feature release has already been downloaded and staged before the Target Feature Update policy is configured.

Windows Feature Version Manager does not remove staged update packages or attempt to undo an update that is already pending restart. If Windows Update already shows a newer feature release as **Pending restart**, review Windows Update before rebooting.

## Windows Servicing Lifecycle

The Target Feature Update policy is not intended to keep a Windows release in service indefinitely.

Microsoft documents that a device configured to stay on a specific feature version can be automatically updated after that version reaches the end of service for its Windows edition.

This utility does not override Microsoft's servicing lifecycle or extend support for an out-of-service Windows release.

## Windows 11 Only

Windows Feature Version Manager is intended for **Windows 11**.

The utility checks the operating system before presenting policy-modification options. If Windows 10 is detected, it displays an unsupported operating system message and exits without making changes.

The Windows 10 rejection path has been tested on Windows 10 22H2.

## Windows 11 Home

Windows 11 Home does not include Local Group Policy Editor, and Microsoft does not document the Target Feature Update policy as applicable to Home in the same way as supported managed editions.

The utility identifies Windows 11 Home and displays a warning before allowing direct registry configuration.

No guarantee is made that Windows Home will honor these registry values with the same policy semantics as editions for which Microsoft documents the policy.

## PowerShell Execution Policy

The included CMD launcher starts the script using:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ...
```

`-ExecutionPolicy Bypass` applies only to that PowerShell process.

The utility does **not** run `Set-ExecutionPolicy` and does not permanently alter the computer's PowerShell execution-policy configuration.

Because Windows may block direct execution of a `.ps1` file depending on the existing PowerShell configuration, using **Run Windows Feature Version Manager.cmd** is the recommended way to launch the utility.

## Requirements

- Windows 11
- Windows PowerShell 5.1
- Administrator privileges for policy changes

No installation, PowerShell modules, package managers, or third-party dependencies are required.

## Additional Notes

- Startup and status checks are read-only.
- Changes require confirmation before they are applied.
- The script does not modify unrelated Windows Update settings, services, tasks, or update components.
- The PowerShell source is provided and can be reviewed before running the utility.

## Microsoft Documentation

For additional information about Microsoft's Target Feature Update policy and Windows servicing:

- [Configure Windows Update client policies via Group Policy](https://learn.microsoft.com/windows/deployment/update/waas-wufb-group-policy)
- [Update Policy CSP](https://learn.microsoft.com/windows/client-management/mdm/policy-csp-update)
- [Windows 11 release information](https://learn.microsoft.com/windows/release-health/windows11-release-information)

## License

Windows Feature Version Manager is released under the **MIT License**.

See `LICENSE` for details.
