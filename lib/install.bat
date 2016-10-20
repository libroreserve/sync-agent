@echo off

setlocal enabledelayedexpansion

IF NOT exist c:\libro-sync-agent (
  mkdir c:\libro-sync-agent
)

cd c:\libro-sync-agent

IF exist CONFIGURATION (
  @echo Configuration file exists; Skipping configuration...
) ELSE (
  @echo Configuring Libro Sync service...
  call set /P WORKING_DIR= "File path to watch [DEFAULT: c:\libro-sync-agent\working]: "
  call set /P LIBRO_API_TOKEN= "Libro API token [REQUIRED]: "
  call set /P RESTAURANT_CODE= "Restaurant code [REQUIRED]: "
  rem IF "%WORKING_DIR%"=="" (SET WORKING_DIR=files)
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

rem check if the git executable is present
where /q git
IF ERRORLEVEL 1 (
  @echo Installing Git...
  call vendor\git-2.10.1-32-bit /verysilent /tasks="modpath"
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

@echo Installing service dependencies...
call gem install bundler --no-rdoc --no-ri
call bundle install --without development test

IF NOT exist CONFIGURATION (
  @echo WORKING_DIR=!WORKING_DIR!>CONFIGURATION
  @echo LIBRO_API_TOKEN=!LIBRO_API_TOKEN!>>CONFIGURATION
  @echo RESTAURANT_CODE=!RESTAURANT_CODE!>>CONFIGURATION
  call git config user.email !RESTAURANT_CODE!@accounts.libroreserve.com
)

@echo Installing Libro Sync service...
call ruby lib/register.rb

@echo done!
timeout 30