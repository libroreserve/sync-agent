# README

## Installation

1. [Download the install script](https://bitbucket.org/jimdurand/libro-sync-agent/downloads/install.bat)
2. Execute the script **as an administrator**
    * Right-click > Run as an administrator
3. That’s it!

### What the script does

The scripts installs Ruby, RubyGems and third party dependencies (gems) required by the agent.

The script also installs **Git** which is used to upgrade the agent.

## Troubleshooting

The *INSTALL* script takes care of upgrading the agent to the latest release and upgrading the Windows service.
In theory, you shouldn't need to use the *UNINSTALL* & *UPGRADE* scripts but if something fishy happens try:

1. Executing the *UNINSTALL* script
2. Rebooting the machine
3. Executing the *UPGRADE* script
4. Executing the *INSTALL* script

If you’re still having issues, [report in a critical issue](https://bitbucket.org/jimdurand/libro-sync-agent/issues/new) and **attach the log file** under `c:\libro-sync-agent\tmp`
