# README

## Installation

1. [Download the install script (right click + save as...)](https://raw.githubusercontent.com/libroreserve/sync-agent/master/lib/install.bat)
2. Execute the script **as an administrator**
    * Right-click > Run as an administrator
3. Make sure to fill in the LIBRO_API_TOKEN & RESTAURANT_CODE when prompted
4. That’s it!

If the installation worked correctly, you will find *c:\libro-sync-agent\working* & *c:\libro-sync-agent\tmp* directories and a log file will be created under *c:\libro-sync-agent\tmp\service-log.txt*.

### If the installation fails

* If c:\libro-sync-agent\vendor dir is empty
    1. Download Git ([for Windows 32 bit](https://github.com/libroreserve/sync-agent/raw/downloads/vendor/Git-2.20.1-32-bit.exe)) ([for Windows 64 bit](https://github.com/libroreserve/sync-agent/raw/downloads/vendor/Git-2.20.1-64-bit.exe)) and place it in the *vendor* dir
    2. If you're not sure which one to get, download both
    3. Re-execute the install script **as an administrator**

* If not, execute *c:\libro-sync-agent\INSTALL* **as an administrator**.

If these directories and files are still missing, follow the **Troubleshooting** section.

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

value              | required? | default                                              |
-------------------|-----------|------------------------------------------------------|
LIBRO_API_TOKEN    | yes       |                                                      |
RESTAURANT_CODE    | yes       |                                                      |
WORKING_DIR        | no        | c:\libro-sync-agent\working                          |
API_ENDPOINT       | no        | https://api.libroreserve.com/inbound/maitre_d/status |
STRIP_INVOICE_DATA | no        | 0                                                    |

### Cohabitation

If the Restock agent is running on the server (the Restock logo will appear on the system tray), do not modify the previous POS configuration. On the Restock agent, you will need to activate the recopy service and set the directory location to `c:\libro-sync-agent\working` as seen in the screenshot below.

![94a2d27d-9987-4c22-b41b-2785655eb4c7](https://user-images.githubusercontent.com/77757014/167418339-9259abd4-38f8-477c-bb59-f36c1283c7ad.png)

The log activity from the POS should therefore still be deposited to the Restock working directory to be then copied by the Restock agent to our working repository.

## Troubleshooting

The *INSTALL* script takes care of upgrading the agent to the latest release and upgrading the Windows service.
In theory, you shouldn't need to use the *UNINSTALL* & *UPGRADE* scripts but if something fishy happens try:

1. Executing the *UNINSTALL* script
2. Rebooting the machine
3. Executing the *UPGRADE* script
4. Executing the *INSTALL* script

If you’re still having issues, [report in a critical issue](https://github.com/libroreserve/sync-agent/issues) and **e-mail us the log file** under `c:\libro-sync-agent\tmp` at admin@libroreserve.com.
