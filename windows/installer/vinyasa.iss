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
; Own id: until now it wrongly shared Bahya Nireekshana's, so Windows treated the apps as one.
AppId={{6AFDD642-E453-4A64-A34D-835F44165BA5}
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

[Code]
const
  OldKey = 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{3B4C320B-9334-480A-84EB-F11BB6917594}_is1';

{ Older versions installed under an id shared with other Brahma apps, often
  into another app's folder. Remove only what is Vinyasa's: its old exe, and
  the old uninstall entry when it still names this app (its uninstaller would
  delete the whole shared folder). Other apps' files are left alone. }
procedure RemoveOld(Root: Integer);
var
  Name, Dir: String;
begin
  if RegQueryStringValue(Root, OldKey, 'DisplayName', Name) and (Name = 'Vinyasa') then
  begin
    if RegQueryStringValue(Root, OldKey, 'InstallLocation', Dir) then
      DeleteFile(AddBackslash(Dir) + 'vinyasa.exe');
    RegDeleteKeyIncludingSubkeys(Root, OldKey);
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
  begin
    RemoveOld(HKCU);
    if IsAdminInstallMode then RemoveOld(HKLM);
  end;
end;
