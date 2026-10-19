; Instalador do Denfis para Windows (Inno Setup 6).
;
; Compilado pelo workflow .github/workflows/windows.yml, que antes monta em
; dist\Denfis o Ruby, o Postgres e a app. Para compilar à mão no Windows:
;   iscc /DAppVersion=1.0.0 packaging\windows\denfis.iss
;
; Instala por usuário, sem pedir administrador: o programa vai para
; %LOCALAPPDATA%\Programs\Denfis e os dados para %LOCALAPPDATA%\Denfis. Atualizar
; é rodar um instalador mais novo por cima — os dados ficam onde estão.
;
; Instalação silenciosa (CI): Denfis-Setup.exe /VERYSILENT /EMAIL=x@y.com /CONTABIL=1

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#define Dist "..\..\dist\Denfis"

[Setup]
AppId={{8F3C2A51-6D4E-4B7A-9C1E-2F5D8A7B3C90}
AppName=Denfis
AppVersion={#AppVersion}
AppPublisher=João Victor Andrade
DefaultDirName={localappdata}\Programs\Denfis
DisableDirPage=yes
DefaultGroupName=Denfis
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\..\dist
OutputBaseFilename=Denfis-Setup
SetupIconFile=denfis.ico
UninstallDisplayIcon={app}\denfis.ico
UninstallDisplayName=Denfis
Compression=lzma2/ultra64
SolidCompression=yes
LZMAUseSeparateProcess=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
; O Denfis em execução é desligado pelo PrepareToInstall, não pelo Restart
; Manager: este mataria o Postgres sem dar tempo de ele fechar direito.
CloseApplications=no

[Languages]
Name: "pt"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "Criar atalho na área de trabalho"

; Uma atualização substitui as três pastas inteiras. Copiar por cima deixaria
; para trás arquivos que a versão nova apagou — e um .rb velho em app\ seria
; carregado pelo Rails como se ainda fizesse parte do código.
[InstallDelete]
Type: filesandordirs; Name: "{app}\app"
Type: filesandordirs; Name: "{app}\ruby"
Type: filesandordirs; Name: "{app}\pgsql"

[Files]
Source: "{#Dist}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Dirs]
Name: "{userdocs}\Denfis\Backups"

[Icons]
Name: "{group}\Denfis"; Filename: "{app}\ruby\bin\ruby.exe"; Parameters: """{app}\denfis.rb"""; WorkingDir: "{app}"; IconFilename: "{app}\denfis.ico"; Comment: "Liga o Denfis e abre no navegador"
Name: "{group}\Fazer backup do Denfis"; Filename: "{app}\ruby\bin\ruby.exe"; Parameters: """{app}\denfis.rb"" backup"; WorkingDir: "{app}"; IconFilename: "{app}\denfis.ico"
Name: "{group}\Pasta de backups do Denfis"; Filename: "{userdocs}\Denfis\Backups"
Name: "{group}\Desligar o Denfis"; Filename: "{app}\ruby\bin\ruby.exe"; Parameters: """{app}\denfis.rb"" parar"; WorkingDir: "{app}"; IconFilename: "{app}\denfis.ico"
Name: "{userdesktop}\Denfis"; Filename: "{app}\ruby\bin\ruby.exe"; Parameters: """{app}\denfis.rb"""; WorkingDir: "{app}"; IconFilename: "{app}\denfis.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\ruby\bin\ruby.exe"; Parameters: """{app}\denfis.rb"""; WorkingDir: "{app}"; Description: "Abrir o Denfis agora"; Flags: postinstall nowait skipifsilent

; Desinstalar desliga o app, mas não apaga os dados nem os backups: quem
; desinstala por engano não perde nada.
[UninstallRun]
Filename: "{app}\ruby\bin\ruby.exe"; Parameters: """{app}\denfis.rb"" parar --sem-pausa"; WorkingDir: "{app}"; Flags: runhidden waituntilterminated; RunOnceId: "PararDenfis"

[Code]
var
  ContaPage: TInputQueryWizardPage;
  ModulosPage: TInputOptionWizardPage;

function PastaDeDados: String;
begin
  Result := ExpandConstant('{localappdata}\Denfis');
end;

// O arquivo do primeiro acesso já existe: é atualização, e a conta também.
// Só o arquivo conta, não o banco: se uma instalação silenciosa veio sem
// e-mail, rodar o instalador de novo tem que voltar a perguntar.
function JaConfigurado: Boolean;
begin
  Result := FileExists(PastaDeDados + '\primeiro-acesso.txt');
end;

procedure InitializeWizard;
begin
  ContaPage := CreateInputQueryPage(wpWelcome,
    'Sua conta', 'Com qual e-mail você vai entrar no Denfis?',
    'A senha você cria no primeiro acesso, direto no navegador.');
  ContaPage.Add('E-mail:', False);
  ContaPage.Values[0] := ExpandConstant('{param:EMAIL|}');

  ModulosPage := CreateInputOptionPage(ContaPage.ID,
    'Módulos', 'O que você vai usar?',
    'O Denfis (finanças pessoais) vem sempre. Marque abaixo se também for usar o módulo contábil.',
    False, False);
  ModulosPage.Add('Também o módulo contábil (pró-labore e fator R)');
  ModulosPage.Values[0] := ExpandConstant('{param:CONTABIL|0}') = '1';
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := ((PageID = ContaPage.ID) or (PageID = ModulosPage.ID)) and JaConfigurado;
end;

function EmailValido(Email: String): Boolean;
var
  Arroba: Integer;
begin
  Arroba := Pos('@', Email);
  Result := (Arroba > 1) and (Pos('.', Copy(Email, Arroba, Length(Email))) > 2) and (Pos(' ', Email) = 0);
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if (CurPageID = ContaPage.ID) and not EmailValido(Trim(ContaPage.Values[0])) then
  begin
    MsgBox('Informe um e-mail válido, como voce@exemplo.com.', mbError, MB_OK);
    Result := False;
  end;
end;

// Um Denfis ligado prende os arquivos do programa; desliga antes de copiar.
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  Ruby: String;
  Codigo: Integer;
begin
  Result := '';
  Ruby := ExpandConstant('{app}\ruby\bin\ruby.exe');
  if FileExists(Ruby) then
    Exec(Ruby, '"' + ExpandConstant('{app}\denfis.rb') + '" parar --sem-pausa',
         ExpandConstant('{app}'), SW_HIDE, ewWaitUntilTerminated, Codigo);
end;

// O lançador lê este arquivo no primeiro início para criar a conta.
procedure CurStepChanged(CurStep: TSetupStep);
var
  Email, Contabil: String;
  Linhas: TArrayOfString;
begin
  if (CurStep <> ssPostInstall) or JaConfigurado then
    Exit;

  Email := Trim(ContaPage.Values[0]);
  if not EmailValido(Email) then
    Exit;

  if ModulosPage.Values[0] then Contabil := '1' else Contabil := '0';

  SetArrayLength(Linhas, 2);
  Linhas[0] := 'email=' + Email;
  Linhas[1] := 'contabil=' + Contabil;
  ForceDirectories(PastaDeDados);
  SaveStringsToUTF8File(PastaDeDados + '\primeiro-acesso.txt', Linhas, False);
end;
