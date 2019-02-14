@echo off

setlocal enabledelayedexpansion

cd c:\libro-sync-agent

SET RUBY=c:\Ruby23\bin\ruby.exe

@echo Uninstalling Libro Sync service...
call "!RUBY!" lib/unregister.rb

@echo Removing service upgrade scheduled task...
schtasks /delete /tn "LibroSyncUpgrade" /f

@echo done!
color a
timeout 5
