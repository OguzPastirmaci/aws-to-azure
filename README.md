# aws-to-azure
The script will create a clone of the AWS Windows VM in Azure. Much of the process like creating a new volume in AWS and attaching it to the VM etc. is automated using AWS Tools for PowerShell, so once you enter the info in the script it should create the clone automatically.

This is not a supported way to migrate from AWS to Azure but it's handy if you want to quickly test your existing AWS Windows VMs on Azure. Use it at your own risk.

If you need a supported way that would handle large amount of migrations, take a look at [Azure Site Recovery](https://azure.microsoft.com/en-us/services/site-recovery/) service.

**Pre-requisites**

- [Azure PowerShell](https://github.com/Azure/azure-powershell) is installed.
- [AWS Tools for PowerShell](https://aws.amazon.com/powershell/) is installed and initialized in the VM that will be migrated.
- [Disk2VHD](https://technet.microsoft.com/en-us/sysinternals/ee656415.aspx) is downloaded and put in the same directory with the script (directory can be changed inside the script if needed).
- Azure subscription data is exported to a file using Save-AzureRmProfile. Default location to put this file is the C:\ drive. Can be changed inside the script if needed.
- The security group of the Windows VM in AWS should allow traffic to TCP 80/443 for uploading the VHD to Azure Storage.

**Usage**

Make the necessary changes for the variables in the script, start a PowerShell prompt as an administrator in the AWS Windows VM you want to create a clone in Azure, and run the script.

**Contributing**

Feel free to check the open issues labeled as enhancements and help with them or create PRs.
