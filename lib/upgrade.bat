@echo off
cd c:/libro-sync-agent

rem check if the git executable is present
where /q git
IF ERRORLEVEL 1 (
  @echo git is missing; run INSTALL first
) ELSE (
  call git checkout .
  call git pull origin master --force
)

@echo Reinstalling Libro Sync service...
call ruby lib/register.rb

@echo done!
timeout 10