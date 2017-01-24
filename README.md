# aws-to-azure
The script will create a clone of the AWS Windows VM in Azure. Much of the process like creating a new volume in AWS and attaching it to the VM etc. is automated using AWS Tool for PowerShell, so once you enter the info in the script it should create the clone automatically.

**Pre-requisites**

- [AWS Tools for PowerShell](https://aws.amazon.com/powershell/) is installed and initialized in the VM that will be migrated
- [Disk2VHD](https://technet.microsoft.com/en-us/sysinternals/ee656415.aspx) is downloaded and put in the same directory with the script (can be changed inside the script if needed)
- Azure subscription data is exported to a file using Save-AzureRmProfile. Default location to put this file is the C:\ drive. Can be changed inside the script if needed.

**Usage**

Make the necessary changes for the variables in the script, start a PowerShell prompt as an administrator, and run the script.

**Contributing**

Feel free to check the open issues labeled as enhancements and help with them or create PRs.

