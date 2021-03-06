@echo off

setlocal enabledelayedexpansion

IF NOT exist c:\libro-sync-agent (
  mkdir c:\libro-sync-agent
)

cd c:\libro-sync-agent

IF NOT exist vendor (mkdir vendor)
IF NOT exist working (mkdir working)


IF exist CONFIGURATION (
  @echo Configuration file exists;
  @echo Skipping configuration...
) ELSE (
  @echo Configuring Libro Sync service...
  call set /P WORKING_DIR= "File path to watch [DEFAULT: c:\libro-sync-agent\working]: "
  call set /P LIBRO_API_TOKEN= "Libro API token [REQUIRED]: "
  call set /P RESTAURANT_CODE= "Restaurant code [REQUIRED]: "
  rem IF "%WORKING_DIR%"=="" (SET WORKING_DIR=files)

  @echo WORKING_DIR=!WORKING_DIR!>CONFIGURATION
  @echo LIBRO_API_TOKEN=!LIBRO_API_TOKEN!>>CONFIGURATION
  @echo RESTAURANT_CODE=!RESTAURANT_CODE!>>CONFIGURATION
)


rem check if the git executable is present

IF exist "%PROGRAMFILES(X86)%\Git\cmd" (
  SET "GIT=%PROGRAMFILES(X86)%\Git\cmd\git.exe"
) ELSE (
  SET "GIT=%PROGRAMFILES%\Git\cmd\git.exe"
)

IF NOT exist "!GIT!" (
  SET GIT_INSTALLER=Git-2.20.1-32-bit.exe
  IF EXIST "%PROGRAMFILES(X86)%" (SET GIT_INSTALLER=Git-2.20.1-64-bit.exe)

  IF NOT exist "vendor\!GIT_INSTALLER!" (
    @echo Downloading Git...
    powershell -command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -OutFile \"c:\libro-sync-agent\vendor\!GIT_INSTALLER!\" \"https://github.com/libroreserve/sync-agent/raw/downloads/vendor/!GIT_INSTALLER!\""
    IF NOT exist "vendor\!GIT_INSTALLER!" (
      @echo Invoke-WebRequest failed...
      powershell -command "(New-Object Net.WebClient).DownloadFile(\"https://github.com/libroreserve/sync-agent/raw/downloads/vendor/!GIT_INSTALLER!\", \"c:\libro-sync-agent\vendor\!GIT_INSTALLER!\")"
    )
    IF NOT exist "vendor\!GIT_INSTALLER!" (
      @echo WebClient also failed...
      powershell -command "Import-Module BitsTransfer; Start-BitsTransfer -Source \"https://s3.amazonaws.com/libro-static-files/sync-agent/!GIT_INSTALLER!\" -Destination \"C:\libro-sync-agent\vendor\!GIT_INSTALLER!\""
    )
    IF NOT exist "vendor\!GIT_INSTALLER!" (
      @echo BitsTransfer also failed... -_-
      @echo Please download "https://github.com/libroreserve/sync-agent/raw/downloads/vendor/!GIT_INSTALLER!", move it to "c:\libro-sync-agent\vendor\" and relaunch this script.
      color c
      timeout 3600
      exit /b
    )
  )
  @echo Installing Git...
  call vendor\!GIT_INSTALLER! /verysilent /tasks="modpath"
)


@echo Fetching the latest code...
IF exist .git (
  call "!GIT!" checkout .
  call "!GIT!" remote set-url origin https://github.com/libroreserve/sync-agent.git
  call "!GIT!" pull origin master --force
) ELSE (
  call "!GIT!" init
  call "!GIT!" remote add origin https://github.com/libroreserve/sync-agent.git
  call "!GIT!" fetch origin master
  call "!GIT!" reset --hard origin/master
  call "!GIT!" config user.email sync-agent@accounts.libroreserve.com
)


rem check if the ruby executable is present

SET RUBY=c:\Ruby23\bin\ruby.exe
SET GEM=c:\Ruby23\bin\gem
SET BUNDLE=c:\Ruby23\bin\bundle

IF NOT exist "!RUBY!" (
  @echo Installing Ruby...
  call vendor\rubyinstaller-2.3.1.exe /verysilent /tasks="modpath"
  SET "PATH=%PATH%;c:\Ruby23\bin"
) ELSE (
  IF exist lib/unregister.rb (
    @echo Uninstalling Libro Sync service...
    call "!RUBY!" lib/unregister.rb
  )
)


rem update rubygem executable is present
FOR /f %%i IN ('!RUBY! !GEM! --version') DO SET "RUBYGEMS_VERSION=%%i"
IF NOT %RUBYGEMS_VERSION% == 3.2.19 (
  @echo Updating RubyGems...
  call "!RUBY!" "!GEM!" install --local vendor\rubygems-update-3.2.19.gem --no-rdoc --no-ri
  call update_rubygems --no-ri --no-rdoc
  call "!RUBY!" "!GEM!" uninstall rubygems-update -x
  call "!RUBY!" "!GEM!" install bundler --no-rdoc --no-ri
)


@echo Installing service dependencies...
IF NOT exist "!BUNDLE!" (
  call "!RUBY!" "!GEM!" install bundler --no-rdoc --no-ri
)
call "!RUBY!" "!BUNDLE!" config set --local without 'development test'
call "!RUBY!" "!BUNDLE!" install

@echo Installing Libro Sync service...
call "!RUBY!" lib/register.rb


@echo Scheduling service upgrade task...
schtasks /delete /tn "LibroSyncUpgrade" /f
schtasks /create /sc daily /tn "LibroSyncUpgrade" /tr "c:\libro-sync-agent\lib\upgrade.bat" /st 03:45 /rl highest /ru system /f
powershell -command "Set-ScheduledTask -TaskName \"LibroSyncUpgrade\" -Settings (New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -WakeToRun)"


@echo done!
color a
timeout 30
