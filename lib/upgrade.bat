@echo off
cd c:/libro-agent

rem check if the git executable is present
where /q git
IF ERRORLEVEL 1 (
  @echo git is missing; run INSTALL first
) ELSE (
  call git checkout .
  call git pull --force
)

@echo done!
timeout 10