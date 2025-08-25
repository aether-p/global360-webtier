# Loadalancer related config

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

#create public IP for load balancer
resource "azurerm_public_ip" "public_ip" {
  name                = "g360_publicIPforLB"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}