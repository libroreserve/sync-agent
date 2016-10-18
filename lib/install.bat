@echo off
cd c:/libro-agent

@echo Installing Ruby...
call vendor\rubyinstaller-2.3.1.exe /verysilent /tasks="modpath"

@echo Updating RubyGems...
call gem install --local vendor\rubygems-update-2.6.7.gem --no-rdoc --no-ri
call update_rubygems --no-ri --no-rdoc
call gem uninstall rubygems-update -x

@echo Installing service dependencies...
call gem install bundler --no-rdoc --no-ri
call bundle install --without development test

@echo Configuring Libro Sync service...
call set /P WORKING_DIR= "File path to watch [files]: "
call set /P LIBRO_API_TOKEN= "Libro API token: "
call set /P RESTAURANT_CODE= "Restaurant code: "
rem IF "%WORKING_DIR%"=="" (SET WORKING_DIR=files)
call del CONFIGURATION
@echo WORKING_DIR=%WORKING_DIR%>CONFIGURATION
@echo LIBRO_API_TOKEN=%LIBRO_API_TOKEN%>>CONFIGURATION
@echo RESTAURANT_CODE=%RESTAURANT_CODE%>>CONFIGURATION

@echo Installing Libro Sync service...
call ruby lib/register.rb

@echo done!
pause