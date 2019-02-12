@echo off
cd c:\libro-sync-agent

rem check if the git executable is present
where /q git
IF ERRORLEVEL 1 (
  @echo git is missing; run INSTALL first
) ELSE (
  call git checkout .
  call git remote set-url origin https://github.com/libroreserve/sync-agent.git
  call git pull origin master --force
)

@echo Restarting Libro Sync service...
call ruby lib/register.rb

@echo done!
timeout 10
