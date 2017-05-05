<#
.SYNOPSIS
Deploys a VM

.DESCRIPTION 
This script takes variables set by you and deploys a Windows Server 2016 Virtual Machine with Managed Disk, Availabililty Set, Public IP address, NIC, Network Security Group and Diagnostics Storage Account. 

.OUTPUTS


.NOTES
Written by: Sarah Lean

Find me on:

* My Blog:	http://www.techielass.com
* Twitter:	https://twitter.com/techielass
* LinkedIn:	http://uk.linkedin.com/in/sazlean
* GitHub:   https://www.github.com/weeyin83


.EXAMPLE


Change Log
V1.00, 02/05/2017 - Initial version

License:

The MIT License (MIT)

Copyright (c) 2017 Sarah Lean

Permission is hereby granted, free of charge, to any person obtaining a copy 
of this software and associated documentation files (the "Software"), to deal 
in the Software without restriction, including without limitation the rights 
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
copies of the Software, and to permit persons to whom the Software is 
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
DEALINGS IN THE SOFTWARE.

#>

#Provide the Subscription ID this deployment should reside in
$subscriptionId = Read-Host -Prompt "Enter the subscription ID this deployment should reside in"

#Provide the name of your resource group
$resourceGroupName = Read-Host -Prompt "Enter the name of the resource group this deployment should reside in"

#Provide the name of the virtual machine
$virtualMachineName = Read-Host -Prompt "Enter the name of the Virtual Machine you wish to build"

#Provide the name of the Managed Disk
$diskName = ('vm-'+$VirtualMachineName.ToLower()+'-os-disk')

#Provide the size of the disks in GB. It should be greater than the VHD file size.
$diskSize = '128'

#Provide the storage type for Managed Disk. PremiumLRS or StandardLRS.
$diskaccountType = Read-Host -Prompt "Enter the type of storage for the managed disk, this should either be StandardLRS or PremiumLRS"

#Provide the region this deployment should live in
$location = Read-Host -Prompt "Enter the region this deployment should reside in"

#Provide the size of the virtual machine
$virtualMachineSize = Read-Host -Prompt "Enter the size of the Virtual Machine you wish to deploy, this should be something along the lines of 'Standard_D2_v2_Promo'"

#Provide the name for the VM NIC
$nicName = ('vm-'+$VirtualMachineName.ToLower()+'-nic')

#Provide name for storage account for boot diagnostics
$storagediagname = ('ia3psa'+$VirtualMachineName.ToLower()+'diag')

#Provide boot diagnostics storage account type
$storagediagsku = Read-Host -Prompt "Enter the type of storage you would like to use for the boot diagnostics storage account, this can be Standard_LRS, Standard_GRS or Standard_RAGRS"

#Provide name for the Network Security Group
$nsgName = Read-Host -Prompt "Enter the name of the Network Security Group you wish to assign to this deployment"

#Provide name for the Availability Set
$availabilitysetname = ('vm-'+$VirtualMachineName.ToLower()+'-avs')

#Provide the name of the virtual network
$vnetname = Read-Host -Prompt "Enter the name of the virtual network you would like to deploy this Virtual Machine to"

#Provide the address prefix of the virtual network
$vnetprefix = Read-Host -Prompt "Enter the address prefix you wish to assign to the virtual network, this should follow CIDR notation, for example 10.0.0.0/24"

#Provide the name of your virtual network subnet
$subnetname = Read-Host -Prompt "Enter the name of the subnet you wish to deploy to your virtual network"

#Provide the address space for your subnet
$subnetprefix = Read-Host -Prompt "Enter the address prefix you wish to assign to the virtual network, this should follow CIDR notation, for example 10.0.0.0/24"


#Provide username and password for the Virtual Name
$user = Read-Host -Prompt "Enter the administrator account name you wish to use for this deployment";  
$password = Read-Host -Prompt "Enter the password you wish to use for this deployment";  
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force;  
$cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);



#You will be promopted to enter the email address and password associated with your account. Azure will authenticate and saves the credential information, and then close the window. 
Login-AzureRmAccount

#Set the context to the subscription Id where Managed Disk will be created
Select-AzureRmSubscription -SubscriptionId $SubscriptionId


#Create Resource Group to hold the deployment
New-AzureRmResourceGroup -Location $location -Name $resourceGroupName

#Create subnet
$subnet = New-AzureRmVirtualNetworkSubnetConfig -AddressPrefix $subnetprefix -Name $subnetname

#Create virtual network
$vnet = New-AzureRmVirtualNetwork -AddressPrefix $vnetprefix -Location $location -Name $vnetname -ResourceGroupName $resourceGroupName -Subnet $subnet

##
##Collect information about the networking components
# Get the VNET to which to connect the NIC
$VNET = Get-AzureRmVirtualNetwork -Name $vnet.name -ResourceGroupName $resourceGroupName
# Get the Subnet ID to which to connect the NIC
$SubnetID = (Get-AzureRmVirtualNetworkSubnetConfig -Name $subnetname -VirtualNetwork $VNET).Id

#Create availability set
New-AzureRmAvailabilitySet -Location $location -Name $availabilitysetname -ResourceGroupName $resourcegroupname -Managed -PlatformFaultDomainCount 2 -PlatformUpdateDomainCount 5
$availabilityset = Get-AzureRmAvailabilitySet -ResourceGroupName $resourcegroupname

##
##
#Initialize virtual machine configuration
$virtualMachine = New-AzureRmVMConfig -VMName $virtualMachineName -VMSize $virtualMachineSize -AvailabilitySetId $availabilityset.id
##
##

##
##
#Create network components
#Create a public IP for the VM  
$publicIp = New-AzureRmPublicIpAddress -Name ('vm-'+$VirtualMachineName.ToLower()+'-ip') -ResourceGroupName $resourceGroupName -Location $location -AllocationMethod Static

#Create an inbound network security group rule for port 3389
$nsgruleRDP = New-AzureRmNetworkSecurityRuleConfig -Name NSGRuleRDP -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow

#Create NSG
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourcegroupname -Location $location -Name $nsgName -SecurityRules $nsgruleRDP

#Create a private NIC for the VM
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $resourcegroupname -Location $location -SubnetId $SubnetID -PublicIpAddressId $publicip.Id -NetworkSecurityGroupId $nsg.Id

##
##
#Create Storage Account for boot diagnostics
$storagediag = New-AzureRmStorageAccount -Location $location -Name $storagediagname -ResourceGroupName $resourcegroupname -SkuName $storagediagsku

##
##Build the VM configuration
#Add NIC to VM
Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $nic.Id

#Set-AzureRMVMBootDiagnostics
Set-AzureRmVMBootDiagnostics -Enable -ResourceGroupName $resourcegroupname -VM $virtualmachine -StorageAccountName $storagediag.StorageAccountName

#Set Operating system
Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter -Version latest -VM $virtualmachine

#Set Computer name and logon credentials
Set-AzureRmVMOperatingSystem -ComputerName $virtualMachineName -Credential $cred -VM $virtualmachine -Windows

#Set the managed disk for the virtual machine
Set-AzureRmVMOSDisk -CreateOption fromImage -VM $virtualmachine -DiskSizeInGB $diskSize -Name $diskName -StorageAccountType $diskaccountType -Windows

##
##Start the VM build
#Create the virtual machine with Managed Disk
New-AzureRmVM -VM $VirtualMachine -ResourceGroupName $resourceGroupName -Location $location -Verbose


#Clear variables
Remove-Variable * -ErrorAction SilentlyContinue