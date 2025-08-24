# Azure web tier config
# NGINX deployed to linux virtual machine scale set behind a load balancer

# Create resource group
resource "azurerm_resource_group" "rg" {
    name = "rg_g360"
    location = var.resource_group_location
}

# Create virtual network
resource "azurerm_virtual_network" "virtual_network" {
    name = "g360_vNet"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    address_space = [ "10.0.0.0/16" ]
}

# Create subnet
resource "azurerm_subnet" "internal" {
  name = "g360_int_subnet"
  resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.virtual_network.name
    address_prefixes = [ "10.0.2.0/24" ]
}

# Create Linux VM Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "scale_set" {
  name                = "g360_webtier_vmss"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard_B1ls"
  instances           = 2

  computer_name_prefix = "myVM"
  admin_username = var.username

  admin_ssh_key {
    username   = var.username
    public_key = azapi_resource_action.ssh_public_key_gen.output.publicKey
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "NIC"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.internal.id
    }
  }
}
