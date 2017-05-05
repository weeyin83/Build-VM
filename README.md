# Build-VM

This PowerShell script will create a Windows Server 2016 Virtual Machine with a Managed Disk, Virtual Network, Subnet, Availability Set, Boot Diagnostics Storage Account, Public IP Address and Network Security Group. 

Ultimately once this script has completed you will have a complete test Virtual Machine with all the required components setup within your Azure Subscription. 

The script creates the Virtual Machine with a 128GB Managed Disk for the Operating System (OS).  The BGInfo extension is also included within the provisioning of this Virtual Machine (VM). 

Included within the script is the creation of a Network Security Group that allows RDP (port 3389) through the Azure networking so you can connect to the VM.  Without this rule you wouldn't be able to connect to the VM after deployment. 


From starting the script to completion takes around 10minutes. 
