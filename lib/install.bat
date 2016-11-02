@echo off

setlocal enabledelayedexpansion

IF NOT exist c:\libro-sync-agent (
  mkdir c:\libro-sync-agent
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
)


rem check if the git executable is present
where /q git
IF ERRORLEVEL 1 (
  IF NOT exist vendor\git-2.10.1-32-bit.exe (
    IF NOT exist vendor ( mkdir vendor )
    @echo Downloading Git...
    powershell -command "$clnt = new-object System.Net.WebClient; $clnt.DownloadFile(\"http://bitbucket.org/jimdurand/libro-sync-agent/downloads/git-2.10.1-32-bit.exe\", \"c:\libro-sync-agent\vendor\git-2.10.1-32-bit.exe\")"
  )
  @echo Installing Git...
  call vendor\git-2.10.1-32-bit /verysilent /tasks="modpath"

  SET PATH=%PATH%;c:\Program Files\Git\cmd
)


@echo Fetching the latest code...
IF exist .git (
  call git checkout .
  call git pull origin master --force
) ELSE (
  call git init
  call git remote add origin https://jimdurand@bitbucket.org/jimdurand/libro-sync-agent.git
  call git fetch origin master
  call git reset --hard origin/master
)


IF NOT exist CONFIGURATION (
  @echo WORKING_DIR=!WORKING_DIR!>CONFIGURATION
  @echo LIBRO_API_TOKEN=!LIBRO_API_TOKEN!>>CONFIGURATION
  @echo RESTAURANT_CODE=!RESTAURANT_CODE!>>CONFIGURATION
  call git config user.email !RESTAURANT_CODE!@accounts.libroreserve.com
)


rem check if the ruby executable is present
where /q ruby
IF ERRORLEVEL 1 (
  @echo Installing Ruby...
  call vendor\rubyinstaller-2.3.1.exe /verysilent /tasks="modpath"

  @echo Updating RubyGems...
  call gem install --local vendor\rubygems-update-2.6.7.gem --no-rdoc --no-ri
  call update_rubygems --no-ri --no-rdoc
  call gem uninstall rubygems-update -x
) ELSE (
  IF exist lib/unregister.rb (
    @echo Uninstalling Libro Sync service...
    call ruby lib/unregister.rb
  )
)


@echo Installing service dependencies...
call gem install bundler --no-rdoc --no-ri
call bundle install --without development test

@echo Installing Libro Sync service...
call ruby lib/register.rb

@echo done!
timeout 30