# aws-to-azure
Migration script to automate moving a Windows VM from AWS to Azure

**Pre-requisites**

- [AWS Tools for PowerShell](https://aws.amazon.com/powershell/) is installed and initialized in the VM that will be migrated
- [Disk2VHD](https://technet.microsoft.com/en-us/sysinternals/ee656415.aspx) is downloaded and put in the same directory with the script (can be changed inside the script if needed)
- Azure subscription data is exported to a file using Save-AzureRmProfile. Default location to put this file is the C:\ drive. Can be changed inside the script if needed.

**Usage**

Make the necessary changes for the variables in the script, start a PowerShell prompt as an administrator, and run the script.

**Contributing**

Check the issues to help with enhancements.

