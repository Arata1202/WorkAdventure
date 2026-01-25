resource "azurerm_resource_group" "workadventure_rg" {
  name     = "workadventure_rg"
  location = var.location
}

resource "azurerm_virtual_network" "workadventure_vnet" {
  name                = "workadventure_vnet"
  location            = azurerm_resource_group.workadventure_rg.location
  resource_group_name = azurerm_resource_group.workadventure_rg.name
  address_space       = [var.vnet_address_space]
}

resource "azurerm_subnet" "workadventure_subnet" {
  name                 = "workadventure_subnet"
  resource_group_name  = azurerm_resource_group.workadventure_rg.name
  virtual_network_name = azurerm_virtual_network.workadventure_vnet.name
  address_prefixes     = [var.subnet_address_prefix]
}

resource "azurerm_public_ip" "workadventure_public_ip" {
  name                = "workadventure_public_ip"
  location            = azurerm_resource_group.workadventure_rg.location
  resource_group_name = azurerm_resource_group.workadventure_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "workadventure_nsg" {
  name                = "workadventure_nsg"
  location            = azurerm_resource_group.workadventure_rg.location
  resource_group_name = azurerm_resource_group.workadventure_rg.name

  # これ
  security_rule {
    name                       = "workadventure_22"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "workadventure_80"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "workadventure_443"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "workadventure_3478_tcp"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3478"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "workadventure_3478_udp"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "3478"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "workadventure_5349_tcp"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5349"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "workadventure_7881_udp"
    priority                   = 160
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "7881"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "workadventure_7882_udp"
    priority                   = 170
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "7882"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "workadventure_10000-10010_udp"
    priority                   = 180
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "10000-10010"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "workadventure_nic" {
  name                = "workadventure_nic"
  location            = azurerm_resource_group.workadventure_rg.location
  resource_group_name = azurerm_resource_group.workadventure_rg.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.workadventure_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.workadventure_public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "workadventure_nsg_association" {
  network_interface_id      = azurerm_network_interface.workadventure_nic.id
  network_security_group_id = azurerm_network_security_group.workadventure_nsg.id
}
