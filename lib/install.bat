setlocal enabledelayedexpansion

@echo off
cd c:/libro-agent

rem check if the ruby executable is present
where /q ruby
IF ERRORLEVEL 1 (
  @echo Installing Ruby...
  call vendor\rubyinstaller-2.3.1.exe /verysilent /tasks="modpath"
) ELSE (
  @echo Uninstalling Libro Sync service...
  call ruby lib/unregister.rb
)

rem check if the git executable is present
where /q git
IF ERRORLEVEL 1 (
  @echo Installing Git...
  call vendor\git-2.10.1-32-bit /verysilent /tasks="modpath"
)
@echo Fetching the latest code...
call git checkout .
call git pull --force

@echo Updating RubyGems...
call gem install --local vendor\rubygems-update-2.6.7.gem --no-rdoc --no-ri
call update_rubygems --no-ri --no-rdoc
call gem uninstall rubygems-update -x

@echo Installing service dependencies...
call gem install bundler --no-rdoc --no-ri
call bundle install --without development test

if exist CONFIGURATION (
  @echo Configuration file exists; Skipping configuration...
) else (
  @echo Configuring Libro Sync service...
  call set /P WORKING_DIR= "File path to watch [files]: "
  call set /P LIBRO_API_TOKEN= "Libro API token: "
  call set /P RESTAURANT_CODE= "Restaurant code: "
  rem IF "%WORKING_DIR%"=="" (SET WORKING_DIR=files)
  rem call del CONFIGURATION
  @echo WORKING_DIR=!WORKING_DIR!>CONFIGURATION
  @echo LIBRO_API_TOKEN=!LIBRO_API_TOKEN!>>CONFIGURATION
  @echo RESTAURANT_CODE=!RESTAURANT_CODE!>>CONFIGURATION
  call git config user.email !RESTAURANT_CODE!@accounts.libroreserve.com
)

@echo Installing Libro Sync service...
call ruby lib/register.rb

@echo done!
pause