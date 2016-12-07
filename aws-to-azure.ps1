$ErrorActionPreference = "Stop"

# AWS instance ID of the VM to be migrated
$instance = ""
# Azure subscription OD
$subscriptionID = ""
# Name of the resource group to be created in Azure
$rgName = ""
# Location of the VM in Azure
$location = ""

# Names of the storage account etc. to be created in Azure. Default is to use the computer name.
$storageAccount = $env:computername.ToLower() -replace "\W"
$containerName = $env:computername.ToLower()
$localVHDName = $env:computername + ".vhd"
$vmName = $env:computername.ToLower()
$subnetName = "mySubNet"
$vnetName = "myVnetName"
$ipName = "$vmName" + "-IP"
$nicName = "$vmName" + "-PrimaryNIC"
$nsgName = "$vmName" + "-Nsg"
$vmSize = "Standard_DS3_v2"


#------------------------------------AWS EC2--------------------------------------------------------

# Get a collection of all volumes attached to the instance and choose /dev/sda1
# The default volume in AWS is /dev/sda1, if you changed this on your VM, change the value here accordingly
$volumes = @(Get-EC2volume) | ? { ($_.Attachments.InstanceId -eq $instance) -and ($_.attachment.device -eq "/dev/sda1")}

# Get the volume's ID
$volumeName = $volumes | % { $_.VolumeId}

# Get the volume's size
$volumeSize = $volumes | % { $_.Size}

# Get the availability zone of the volume
$AZ = (Get-EC2volume -VolumeId $volumeName).AvailabilityZone

# Setting the region for EC2 Run Command
Set-DefaultAWSRegion -Region $AZ

# Create a new volume with the same size of the boot volume in the same availability zone

$cloneVolume = New-EC2Volume -Size $volumeSize -VolumeType gp2 -AvailabilityZone $AZ

### TODO: Add a better check here to make sure the status of the volume becomes available/created

Start-Sleep 10

# Attach the created volume to the VM
$cloneVolumeID = $cloneVolume.VolumeId

Add-EC2Volume -InstanceId $instance -VolumeId $cloneVolumeID -Device xvdp -Force

### TODO: Add a check here to make sure the status is attached


#-----------------------------------IN THE VM-------------------------------------------------------

# Get the first unused letter to assing to the new disk
$usedLetters  = Get-PSDrive | Select-Object -Expand Name |
         Where-Object { $_.Length -eq 1 }
$availableLetterForReservedVolume = 67..90 | ForEach-Object { [string][char]$_ } |
         Where-Object { $usedLetters -notcontains $_ } |
         Select-Object -First 1

# Add System Reserved volume as a drive with diskpart (that's necessary for the VM to be able to boot)
New-Item -Name addReservedVolume.txt -ItemType file -force | OUT-NULL
Add-Content -Path addReservedVolume.txt “sel disk 0”
Add-Content -Path addReservedVolume.txt “sel part 1”
Add-Content -Path addReservedVolume.txt “assign letter=$availableLetterForReservedVolume noerr”
$addReservedVolume=(diskpart /s addReservedVolume.txt) | Out-Null


# Remove the System Reserved volume as a drive with diskpart
New-Item -Name removeReservedVolume.txt -ItemType file -force | OUT-NULL
Add-Content -Path removeReservedVolume.txt “sel disk 0”
Add-Content -Path removeReservedVolume.txt “sel part 1”
Add-Content -Path removeReservedVolume.txt “remove letter=$availableLetterForReservedVolume noerr”
$removeReservedVolume=(diskpart /s removeReservedVolume.txt) | Out-Null


# Get the first unused letter to assing to the new disk that we'll put the cloned VHD into
$usedLetters  = Get-PSDrive | Select-Object -Expand Name |
         Where-Object { $_.Length -eq 1 }
$availableLetterForCloning = 67..90 | ForEach-Object { [string][char]$_ } |
         Where-Object { $usedLetters -notcontains $_ } |
         Select-Object -First 1


# Get the newly added disk and create a new partition 
Get-Disk | Where partitionstyle -eq ‘raw’ | Initialize-Disk -PartitionStyle MBR -PassThru -AsJob | Wait-Job | Receive-Job | New-Partition -DriveLetter $availableLetterForCloning -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel “Migration” -Confirm:$false


# Clone the drive/s with Disk2VHD. Change the drive/s if you're cloning any disk other than the C drive
$clonedDiskTarget = $availableLetterForCloning + $localVHDName
$process = "disk2vhd.exe"
$drive1 = "S:"
$drive2 = "C:"
&$process $drive1 $drive2 $clonedDiskTarget "-accepteula" | echo "Waiting for the disk to be cloned"


# Enter the location of your Azure profile file

# Select-AzureRmProfile -Path "c:\azureprofile.json"
 
Select-AzureRmSubscription -SubscriptionId $subscriptionID
 
# Get-AzureRmStorageAccount

New-AzureRmResourceGroup -Name $rgName -Location $location
  
New-AzureRmStorageAccount -ResourceGroupName $rgName -Name $storageAccount -Location $location -SkuName "Standard_LRS" -Kind "Storage"
 
 
# Upload the VHD
 
$osDiskUri = "https://$storageAccount.blob.core.windows.net/$containerName/$localVHDName"
 
Add-AzureRmVhd -ResourceGroupName $rgName -Destination $osDiskUri -LocalFilePath $clonedDiskTarget

# Create the subnet

$singleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.0.0/24
 
# Create the Vnet

$vnet = New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $singleSubnet
 
# Create a public IP & NIC

$pip = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $rgName -DomainNameLabel $vmName -Location $location -AllocationMethod Dynamic
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id
 
# Create NSG and add RDP rule
 
$rdpRule = New-AzureRmNetworkSecurityRuleConfig -Name RDP -Description "Allow RDP" -Access Allow -Protocol Tcp -Direction Inbound -Priority 110 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
 
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $rgName -Location $location -Name $nsgName -SecurityRules $rdpRule
  

# Set the VM name and size
 
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize
 
# Add the NIC
$vm = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id $nic.Id
 
# Add the OS disk by using the URL of the copied OS VHD

$osDiskName = $vmName + "osDisk"
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $osDiskUri -CreateOption attach -Windows

# Create the new VM
New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vm
