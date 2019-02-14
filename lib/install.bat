@echo off

setlocal enabledelayedexpansion

IF NOT exist c:\libro-sync-agent (
  mkdir c:\libro-sync-agent
  mkdir c:\libro-sync-agent\working
  mkdir c:\libro-sync-agent\vendor
)

cd c:\libro-sync-agent


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
where /q git
IF ERRORLEVEL 1 (
  SET GIT_FILENAME=Git-2.20.1-32-bit.exe
  IF EXIST "%PROGRAMFILES(X86)%" (SET GIT_FILENAME=Git-2.20.1-64-bit.exe)

  IF NOT exist vendor\!GIT_FILENAME! (
    IF NOT exist vendor ( mkdir vendor )
    @echo Downloading Git...
    rem powershell -command "$clnt = new-object System.Net.WebClient; $clnt.DownloadFile(\"https://github.com/libroreserve/sync-agent/raw/downloads/vendor/!GIT_FILENAME!\", \"c:\libro-sync-agent\vendor\!GIT_FILENAME!\")"
    powershell -command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -OutFile \"c:\libro-sync-agent\vendor\!GIT_FILENAME!\" \"https://github.com/libroreserve/sync-agent/raw/downloads/vendor/!GIT_FILENAME!\""
  )
  @echo Installing Git...
  call vendor\!GIT_FILENAME! /verysilent /tasks="modpath"

  IF exist "%PROGRAMFILES(X86)%\Git\cmd" (
    SET "PATH=%PATH%;%PROGRAMFILES(X86)%\Git\cmd"
  ) else (
    SET "PATH=%PATH%;%PROGRAMFILES%\cmd"
  )

  rem restart script to make sure the git executables are loaded
  @echo The script will now relaunch in a new window.
  timeout 20
  start cmd /c call %~f0
  exit /b
)


@echo Fetching the latest code...
IF exist .git (
  call git checkout .
  call git remote set-url origin https://github.com/libroreserve/sync-agent.git
  call git pull origin master --force
) ELSE (
  call git init
  call git remote add origin https://github.com/libroreserve/sync-agent.git
  call git fetch origin master
  call git reset --hard origin/master
  call git config user.email sync-agent@accounts.libroreserve.com
)

rem check if the ruby executable is present
where /q ruby
IF ERRORLEVEL 1 (
  @echo Installing Ruby...
  call vendor\rubyinstaller-2.3.1.exe /verysilent /tasks="modpath"
  SET "PATH=%PATH%;c:\Ruby23\bin"

  rem restart script to make sure the ruby executables are loaded
  @echo The script will now relaunch in a new window.
  timeout 20
  rem start cmd /c call %~f0
  start cmd /c call c:\libro-sync-agent\lib\install.bat
  exit /b
) ELSE (
  IF exist lib/unregister.rb (
    @echo Uninstalling Libro Sync service...
    call ruby lib/unregister.rb
  )
)

rem update rubygem executable is present
FOR /f %%i IN ('gem --version') DO SET "RUBYGEMS_VERSION=%%i"
IF NOT %RUBYGEMS_VERSION% == 2.6.7 (
  @echo Updating RubyGems...
  call gem install --local vendor\rubygems-update-2.6.7.gem --no-rdoc --no-ri
  call update_rubygems --no-ri --no-rdoc
  call gem uninstall rubygems-update -x
)


@echo Installing service dependencies...
where /q bundle
IF ERRORLEVEL 1 (
  call gem install bundler --no-rdoc --no-ri
)
call bundle install --without development test

@echo Installing Libro Sync service...
call ruby lib/register.rb


@echo Scheduling service upgrade task...
schtasks /delete /tn "LibroSyncUpgrade" /f
schtasks /create /sc daily /tn "LibroSyncUpgrade" /tr "c:\libro-sync-agent\lib\upgrade.bat" /st 03:45 /rl highest /ru system /f
powershell -command "Set-ScheduledTask -TaskName \"LibroSyncUpgrade\" -Settings (New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -WakeToRun)"


@echo done!
timeout 15
