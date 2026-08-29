# Security Policy

JellyBox is an unofficial audio client for Jellyfin, available on macOS, iOS, and Android (with Linux and Windows support in progress). We take the security of the app and its users seriously and appreciate responsible disclosure of any vulnerabilities.

## Supported Versions

Only the latest released version of JellyBox receives security fixes. Older releases are not patched retroactively — please update to the most recent version from the [App Store](https://apps.apple.com/us/app/jellybox-player/id6469732117) or the [GitHub releases page](https://github.com/avdept/JellyBoxPlayer/releases) before reporting an issue, and confirm it still reproduces there.

| Version        | Supported          |
| -------------- | ------------------ |
| Latest release | :white_check_mark: |
| Older releases | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues, discussions, or pull requests.**

Instead, use one of these private channels:

1. **GitHub private vulnerability reporting (preferred):** Go to the repository's [Security tab](https://github.com/avdept/JellyBoxPlayer/security) and click "Report a vulnerability". This keeps the report private between you and the maintainer.
2. **Direct contact:** If you cannot use GitHub's reporting flow, reach out via the contact details on the maintainer's GitHub profile ([@avdept](https://github.com/avdept)) to arrange a private channel.

### What to include

To help triage and fix the issue quickly, please include as much of the following as you can:

- The type of issue (e.g. credential leakage, insecure storage, improper certificate validation, injection)
- Affected platform(s) and app version (iOS, macOS, Android, or a specific build/commit)
- Step-by-step instructions to reproduce the issue
- Proof-of-concept code or screenshots, if available
- The impact of the issue, including how an attacker might exploit it
- Any suggested remediation, if you have one

### What to expect

- **Acknowledgement** of your report within **72 hours**
- An initial **assessment and severity triage** within **7 days**
- Regular updates as a fix is developed
- A fix released in the next app update, prioritized by severity
- Credit in the release notes for the fix, unless you prefer to remain anonymous

As this is a solo-maintained open-source project, response times may occasionally be longer, but every report will be read and taken seriously.

## Scope

### In scope

- The JellyBox client applications (iOS, macOS, Android, and desktop builds) and all code in this repository
- Handling and storage of Jellyfin server credentials and access tokens on-device
- Network communication between JellyBox and a Jellyfin server (e.g. TLS handling, certificate validation)
- Vulnerabilities in the bundled native components in this repository (`mediakeys_proxy`, `native_route_picker`, the vendored `just_audio_background` package)
- Crash-reporting/telemetry data handling (Sentry integration)

### Out of scope

- Vulnerabilities in the **Jellyfin server** itself — please report those to the [Jellyfin project](https://github.com/jellyfin/jellyfin/security)
- Vulnerabilities in third-party dependencies with no demonstrated impact on JellyBox (report upstream, but feel free to notify us so we can bump the dependency)
- Issues that require a compromised or jailbroken/rooted device
- Attacks requiring physical access to an unlocked device
- Denial of service against a user's own Jellyfin server
- Social engineering of the maintainer or users
- Reports from automated scanners without a validated, exploitable finding

## Disclosure Policy

Please give us a reasonable amount of time to remediate the issue before any public disclosure. We follow coordinated disclosure: once a fix has been released, we are happy to coordinate on public disclosure timing and will credit you for the discovery.

We will not pursue legal action against researchers who act in good faith, follow this policy, avoid privacy violations and data destruction, and do not exploit issues beyond what is necessary to demonstrate them.

Thank you for helping keep JellyBox and its users safe!
