@echo off

setlocal enabledelayedexpansion

cd c:\libro-sync-agent

rem check if the git executable is present

IF exist "%PROGRAMFILES(X86)%\Git\cmd" (
  SET "GIT=%PROGRAMFILES(X86)%\Git\cmd\git.exe"
) ELSE (
  SET "GIT=%PROGRAMFILES%\Git\cmd\git.exe"
)

IF NOT exist "!GIT!" (
  @echo git is missing; run INSTALL first
) ELSE (
  call "!GIT!" checkout .
  call "!GIT!" remote set-url origin https://github.com/opentable/libro-sync-agent.git
  call "!GIT!" fetch origin main
  call "!GIT!" checkout -B main origin/main
)


SET RUBY=c:\Ruby23\bin\ruby.exe

@echo Restarting Libro Sync service...
call "!RUBY!" lib/register.rb

@echo done!
color a
timeout 5
