# Changelog

All notable changes to Windows Feature Version Manager will be documented in this file.

## [1.0.1] - 2026-09-30

### Initial Public Release

- View the currently installed Windows version, build, edition, and Target Feature Update policy status.
- Set or change the Windows 11 Target Feature Update version.
- Remove the Target Feature Update policy values managed by the utility and return the policy to Not Configured.
- Detect incomplete or custom Target Feature Update policy configurations.
- Validate normal Windows feature-version input while allowing manual confirmation for nonstandard version strings.
- Require confirmation before applying or removing policy settings.
- Verify policy state after changes are made.
- Automatically request administrator elevation through UAC when required.
- Include a CMD launcher using a process-only PowerShell execution-policy bypass.
- Detect unsupported Windows versions and prevent policy modification outside Windows 11.
- Warn Windows 11 Home users about Microsoft's documented policy applicability.
- Warn when a newer Feature Update may already be staged and pending restart.
- Keep all policy changes limited to:
  - `ProductVersion`
  - `TargetReleaseVersion`
  - `TargetReleaseVersionInfo`

### Notes

- This utility does not disable Windows Update or Windows Update services.
- It does not remove installed or staged Windows update packages.
- It does not permanently modify the PowerShell execution policy.
- Windows 10 is not supported for policy modification.
