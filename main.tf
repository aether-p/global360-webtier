# Azure web tier config
# NGINX deployed to linux virtual machine scale set behind a load balancer

# Cloud init filie
locals {
  cloud_init = templatefile("${path.module}/cloud-init.yaml", {})
}

# Create resource group
resource "azurerm_resource_group" "rg" {
  name     = "rg_g360"
  location = var.resource_group_location
}

# Create Linux VM Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "scale_set" {
  name                = "g360_webtier_vmss"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard_B1ls"
  instances           = 2
  custom_data         = base64encode(local.cloud_init)


  computer_name_prefix = "myVM"
  admin_username       = var.username

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
    name                      = "NIC"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.internal.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.backend_address_pool.id]
    }
  }

  boot_diagnostics {
    storage_account_uri = null
  }
}