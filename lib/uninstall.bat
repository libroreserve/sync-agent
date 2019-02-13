@echo off
cd c:\libro-sync-agent

@echo Uninstalling Libro Sync service...
ruby lib/unregister.rb

@echo Removing service upgrade scheduled task...
schtasks /delete /tn "LibroSyncUpgrade" /f

@echo done!
timeout 10