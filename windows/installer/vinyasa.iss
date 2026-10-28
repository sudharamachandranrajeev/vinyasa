; Vinyasa for Windows: Inno Setup script. The release workflow builds the app
; (flutter build windows) and compiles this with
;   iscc /DAppVersion=0.1.0 windows\installer\vinyasa.iss
; Installs for the current user by default (no admin prompt). Uninstalling
; leaves the encrypted data in %APPDATA%\Vinyasa alone.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#define Release "..\..\build\windows\x64\runner\Release"

[Setup]
AppId={{3B4C320B-9334-480A-84EB-F11BB6917594}
AppName=Vinyasa
AppVersion={#AppVersion}
AppVerName=Vinyasa {#AppVersion}
AppPublisher=Rajeev Sudharamachandran
DefaultDirName={autopf}\Vinyasa
DefaultGroupName=Vinyasa
DisableProgramGroupPage=yes
OutputDir=..\..\build\installer
OutputBaseFilename=Vinyasa-{#AppVersion}-windows-x64-setup
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\vinyasa.exe
UninstallDisplayName=Vinyasa
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
CloseApplications=yes
; Windows 10 1809 or later (and Windows 11)
MinVersion=10.0.17763

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#Release}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Vinyasa"; Filename: "{app}\vinyasa.exe"; Comment: "Space organiser"
Name: "{autodesktop}\Vinyasa"; Filename: "{app}\vinyasa.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\vinyasa.exe"; Description: "{cm:LaunchProgram,Vinyasa}"; Flags: nowait postinstall skipifsilent
