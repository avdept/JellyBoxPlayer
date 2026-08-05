; Inno Setup script for the JellyBox Windows installer.
;
; Compiled in CI by .github/workflows/windows-release.yaml:
;   ISCC /DMyAppVersion=2.0.0 /DAppSourceDir=<staged build> /DAppOutputDir=<out> jellybox.iss
;
; The defaults below let it also be compiled locally straight from a
; `flutter build windows --release` output, with no /D arguments. Relative
; paths here resolve against this script's own directory, which is what
; Inno's [Setup] SourceDir defaults to (hence the App* prefixes below —
; a bare `SourceDir` define would shadow that built-in confusingly).

; Requires Inno Setup 7+: SetupArchitecture below does not exist in 6.x, and
; without this guard a 6.x compile fails with a bare "unknown directive".
#if VER < EncodeVer(7,0,0)
  #error Inno Setup 7 or newer is required to compile this script.
#endif

#define MyAppName "JellyBox"
#define MyAppPublisher "JellyBox"
#define MyAppURL "https://github.com/avdept/JellyBoxPlayer"
#define MyAppExeName "jellybox.exe"

#ifndef MyAppVersion
  #define MyAppVersion "0.0.0"
#endif
; VersionInfoVersion accepts only a numeric x.y.z[.w], so a prerelease tag such
; as v2.1.0-beta1 would abort the compile outright. Strip any suffix for the
; Windows file-version resource; AppVersion and the output filename keep the
; full string, so "2.1.0-beta1" still shows in Apps & features and the .exe name.
#define NumericVersion MyAppVersion
#if Pos("-", NumericVersion) > 0
  #define NumericVersion Copy(NumericVersion, 1, Pos("-", NumericVersion) - 1)
#endif

#ifndef AppSourceDir
  #define AppSourceDir "..\..\build\windows\x64\runner\Release"
#endif
#ifndef AppOutputDir
  #define AppOutputDir "..\..\build\windows\installer"
#endif

[Setup]
; AppId must stay constant across versions so installs upgrade in place
; instead of stacking up as separate entries in Apps & features.
AppId={{C2A3707E-326A-44AC-B72F-47851151F3D0}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases
VersionInfoVersion={#NumericVersion}

DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
UninstallDisplayName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}

; Per-user install by default: it needs no UAC elevation, which matters
; because the binary is unsigned and an elevated unsigned installer shows a
; scarier "unknown publisher" prompt. Users who want a machine-wide install
; can still pick it from the dialog.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

; The app is x64-only, so build a native 64-bit installer (Inno 7+) rather
; than the legacy 32-bit stub. x64compatible also covers Arm64 Windows
; running x64 binaries under emulation.
SetupArchitecture=x64
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

OutputDir={#AppOutputDir}
; Deliberately version-less so the release asset keeps a stable name and
; https://github.com/avdept/JellyBoxPlayer/releases/latest/download/windows-setup.exe
; can be linked directly. The version still ships inside the installer via
; AppVersion / VersionInfoVersion above.
OutputBaseFilename=windows-setup
SetupIconFile=..\runner\resources\app_icon.ico
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
DisableProgramGroupPage=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#AppSourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
