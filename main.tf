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

# Create virtual network
resource "azurerm_virtual_network" "virtual_network" {
  name                = "g360_vNet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}

# Create subnet
resource "azurerm_subnet" "internal" {
  name                 = "g360_int_subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["10.0.2.0/24"]
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

# Create Network Security Group and Rule
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "myNetworkSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

#create public IP for load balancer
resource "azurerm_public_ip" "public_ip" {
  name                = "g360_publicIPforLB"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create load balancer and front end IP
resource "azurerm_lb" "loadbalancer" {
  name                = "g360_loadbalancer"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "g360_publicIP"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

# Create backend addres pool 
resource "azurerm_lb_backend_address_pool" "backend_address_pool" {
  loadbalancer_id = azurerm_lb.loadbalancer.id
  name            = "g360_BackEndAdressPool"
}

# Create load balancing Rule
resource "azurerm_lb_rule" "lb_rule" {
  loadbalancer_id                = azurerm_lb.loadbalancer.id
  name                           = "myLBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "g360_publicIP"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_address_pool.id]
}

# Create Inbound NAT Rules 
resource "azurerm_lb_nat_rule" "my_terraform_lb_nat_rule" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.loadbalancer.id
  name                           = "ssh"
  protocol                       = "Tcp"
  frontend_port_start            = 22
  frontend_port_end              = 30
  backend_port                   = 22
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_address_pool.id
  frontend_ip_configuration_name = "g360_publicIP"
}