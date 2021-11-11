terraform{
    required_version = ">=0.13"

    required_providers {
        azurerm = {
            source = "hashicorp/azurerm"
            version = ">=2.46.0"
        }
    }
}

provider "azurerm" {
  skip_provider_registration = false
  features{
  }
}

resource "azurerm_resource_group" "example" {
  name = "infra2"
  location = "East US"
}

resource "azurerm_virtual_network" "example-infra2" {
  name                = "virtualNetwork1"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "Production"
    materia = "infra2"
    faculdade = "impacta"

  }
}

resource "azurerm_subnet" "example-sb-infra2" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example-infra2.name
  address_prefixes     = ["10.0.1.0/24"]

}

resource "azurerm_public_ip" "example-ip-infra2" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_security_group" "nsg-infra2" {
  name                = "acceptanceTestSecurityGroup1"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface" "nic-infra2" {
  name                = "example-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "infra2"
    subnet_id                     = azurerm_subnet.example-sb-infra2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.example-ip-infra2.id
  }
}

resource "azurerm_virtual_machine" "vm-infra2" {
  name                  = "infra2-vm"
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  network_interface_ids = [azurerm_network_interface.nic-infra2.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "staging"
  }
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.nic-infra2.id
  network_security_group_id = azurerm_network_security_group.nsg-infra2.id
}

output "public_ip_vm" {
  value = azurerm_public_ip.example-ip-infra2.ip_address
}