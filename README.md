# README

## Installation

1. [Download the install script](https://bitbucket.org/jimdurand/libro-sync-agent/downloads/install.bat)
2. Execute the script **as an administrator**
    * Right-click > Run as an administrator
3. That’s it!

### What the script does

1. Installs Ruby, RubyGems and third party dependencies (gems) required by the agent
2. Installs **Git**, used to upgrade the agent
3. Generates a `c:\libro-sync-agent\CONFIGURATION` file
4. Installs the latest release of the agent
5. Configures the Windows service running the agent
6. Starts the Windows service

### Configuration

After the initial install, you will need to edit the *CONFIGURATION* manually and *restart* the Windows service if you need to update one of the parameters; *UPGRADE* or *INSTALL* scripts will restart the Windows service.

Here is a list of supported parameters:

value             | required? | default                                              |
------------------|-----------|------------------------------------------------------|
LIBRO_API_TOKEN   | yes       |                                                      |
RESTAURANT_CODE   | yes       |                                                      |
WORKING_DIR       | no        | c:\libro-sync-agent\working                          |
API_ENDPOINT      | no        | https://api.libroreserve.com/inbound/maitre_d/status |

## Troubleshooting

The *INSTALL* script takes care of upgrading the agent to the latest release and upgrading the Windows service.
In theory, you shouldn't need to use the *UNINSTALL* & *UPGRADE* scripts but if something fishy happens try:

1. Executing the *UNINSTALL* script
2. Rebooting the machine
3. Executing the *UPGRADE* script
4. Executing the *INSTALL* script

If you’re still having issues, [report in a critical issue](https://bitbucket.org/jimdurand/libro-sync-agent/issues/new) and **attach the log file** under `c:\libro-sync-agent\tmp`
