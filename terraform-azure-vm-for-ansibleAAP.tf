resource "azurerm_network_interface" "main" {
  name                = "vm-mgmt-westus-ansible-001-nic"
  location            = "westus"
  resource_group_name = "resource-group-name"

  ip_configuration {
    name                          = "nicconfiguration"
    subnet_id                     = "/subscriptions/cf3bbde2-484b-4384-b685-5bcfc322755d/resourceGroups/rg-MGMT-WestUS-vnet/providers/Microsoft.Network/virtualNetworks/vnet-MGMT-WestUS/subnets/snet-infra"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "vm-mgmt-westus-ansible-001"
  location              = "westus"
  resource_group_name   = "resource-group-name"
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_D2s_v3"

  storage_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "85-gen2"
    version   = "latest"
  }
  storage_os_disk {
    name              = "vm-mgmt-westus-anisble-001_OsDisk_1_e7df8437c90a4a608b26b7ecde2feede"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
    disk_size_gb      = 64
  }
  os_profile {
    computer_name  = "vm-mgmt-westus-ansibleautomationplatform"
    admin_username = "localadmin"
    admin_password = "password45w35w5dawd"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    BuildDate    = "09/28/22"
    "AppName"    = "Ansible Automation Platform (AAP)"
    "Department" = "Ops"
    "created-by" = "david.ruffin@amtwoundcare.com"
  }
}
