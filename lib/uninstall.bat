@echo off
cd c:\libro-sync-agent

@echo Uninstalling Libro Sync service...
ruby lib/unregister.rb

@echo done!
timeout 10