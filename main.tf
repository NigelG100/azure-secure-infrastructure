resource "azurerm_resource_group" "project" {
  name     = "rg-secure-infra"
  location = "East US"

  tags = {
    Environment = "Portfolio"
    Project     = "Secure-Azure-Infrastructure"
    ManagedBy   = "Terraform"
  }
}


resource "azurerm_virtual_network" "project" {
  name                = "vnet-secure-infra"
  address_space       = ["10.20.0.0/16"]
  location            = azurerm_resource_group.project.location
  resource_group_name = azurerm_resource_group.project.name

  tags = {
    Environment = "Portfolio"
    Project     = "Secure-Azure-Infrastructure"
    ManagedBy   = "Terraform"
  }
}


resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.project.name
  virtual_network_name = azurerm_virtual_network.project.name
  address_prefixes     = ["10.20.1.0/24"]
}


resource "azurerm_subnet" "app" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.project.name
  virtual_network_name = azurerm_virtual_network.project.name
  address_prefixes     = ["10.20.2.0/24"]
}
resource "azurerm_subnet" "db" {
  name                 = "snet-db"
  resource_group_name  = azurerm_resource_group.project.name
  virtual_network_name = azurerm_virtual_network.project.name
  address_prefixes     = ["10.20.3.0/24"]
}
resource "azurerm_network_security_group" "web" {
  name                = "nsg-web"
  location            = azurerm_resource_group.project.location
  resource_group_name = azurerm_resource_group.project.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow-SSH-My-IP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_source_ip
    destination_address_prefix = "*"
  }
  tags = {
    Environment = "Portfolio"
    Project     = "Secure-Azure-Infrastructure"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_network_security_group" "app" {
  name                = "nsg-app"
  location            = azurerm_resource_group.project.location
  resource_group_name = azurerm_resource_group.project.name

  security_rule {
    name                       = "Allow-Web-To-App"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "10.20.1.0/24"
    destination_address_prefix = "10.20.2.0/24"
  }
  security_rule {
    name                       = "Deny-Other-VNet-Inbound"
    priority                   = 400
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = "Portfolio"
    Project     = "Secure-Azure-Infrastructure"
    ManagedBy   = "Terraform"
    Tier        = "App"
  }
}
resource "azurerm_network_security_group" "db" {
  name                = "nsg-db"
  location            = azurerm_resource_group.project.location
  resource_group_name = azurerm_resource_group.project.name

  security_rule {
    name                       = "Allow-App-To-Postgres"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "10.20.2.0/24"
    destination_address_prefix = "10.20.3.0/24"
  }
  security_rule {
    name                       = "Deny-Other-VNet-Inbound"
    priority                   = 400
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = "Portfolio"
    Project     = "Secure-Azure-Infrastructure"
    ManagedBy   = "Terraform"

  }

}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}

resource "azurerm_subnet_network_security_group_association" "db" {
  subnet_id                 = azurerm_subnet.db.id
  network_security_group_id = azurerm_network_security_group.db.id
}

resource "azurerm_public_ip" "web" {
  name                = "pip-web"
  location            = azurerm_resource_group.project.location
  resource_group_name = azurerm_resource_group.project.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = "Portfolio"
    Project     = "Secure-Azure-Infrastructure"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_network_interface" "web" {
  name                = "nic-web"
  location            = azurerm_resource_group.project.location
  resource_group_name = azurerm_resource_group.project.name

  ip_configuration {
    name                          = "web-ipconfig"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web.id
  }

  tags = {
    Environment = "Portfolio"
    Project     = "Secure-Azure-Infrastructure"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_linux_virtual_machine" "web" {
  name                = "vm-web"
  resource_group_name = azurerm_resource_group.project.name
  location            = azurerm_resource_group.project.location
  size                = "Standard_F1als_v7"
  admin_username      = "azureadmin"
  custom_data         = base64encode(file("${path.module}/scripts/web-setup.sh"))
  network_interface_ids = [
    azurerm_network_interface.web.id
  ]

  admin_ssh_key {
    username   = "azureadmin"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }





  tags = {
    Environment = "Portfolio"
    Project     = "Secure-Azure-Infrastructure"
    ManagedBy   = "Terraform"
    Tier        = "Web"
  }
}


resource "azurerm_network_interface" "app" {
  name                = "nic-app"
  location            = azurerm_resource_group.project.location
  resource_group_name = azurerm_resource_group.project.name

  ip_configuration {
    name                          = "app-ipconfig"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.20.2.4"
  }

  tags = {
    Environment = "Portfolio"
    Project     = "Secure-Azure-Infrastructure"
    ManagedBy   = "Terraform"
    Tier        = "App"
  }
}

resource "azurerm_linux_virtual_machine" "app" {
  name                = "vm-app"
  resource_group_name = azurerm_resource_group.project.name
  location            = azurerm_resource_group.project.location
  size                = "Standard_F1als_v7"
  admin_username      = "azureadmin"
  depends_on = [
    azurerm_subnet_nat_gateway_association.app
  ]
  custom_data = base64encode(<<-EOF
#!/bin/bash
export DB_PASSWORD='${var.db_password}'
${file("${path.module}/scripts/app-setup.sh")}
EOF
  )
  network_interface_ids = [
    azurerm_network_interface.app.id
  ]

  admin_ssh_key {
    username   = "azureadmin"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    Environment = "Portfolio"
    Project     = "Secure-Azure-Infrastructure"
    ManagedBy   = "Terraform"
    Tier        = "App"
  }
}
# =========================
# OUTBOUND CONNECTIVITY
# =========================

resource "azurerm_public_ip" "nat" {
  name                = "pip-nat"
  location            = azurerm_resource_group.project.location
  resource_group_name = azurerm_resource_group.project.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = "Portfolio"
    Project     = "Secure-Azure-Infrastructure"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_nat_gateway" "project" {
  name                    = "nat-secure-infra"
  location                = azurerm_resource_group.project.location
  resource_group_name     = azurerm_resource_group.project.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10

  tags = {
    Environment = "Portfolio"
    Project     = "Secure-Azure-Infrastructure"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_nat_gateway_public_ip_association" "project" {
  nat_gateway_id       = azurerm_nat_gateway.project.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "app" {
  subnet_id      = azurerm_subnet.app.id
  nat_gateway_id = azurerm_nat_gateway.project.id
}

resource "azurerm_subnet_nat_gateway_association" "db" {
  subnet_id      = azurerm_subnet.db.id
  nat_gateway_id = azurerm_nat_gateway.project.id
}
# =========================
# DATABASE TIER
# =========================

resource "azurerm_network_interface" "db" {
  name                = "nic-db"
  location            = azurerm_resource_group.project.location
  resource_group_name = azurerm_resource_group.project.name

  ip_configuration {
    name                          = "db-ipconfig"
    subnet_id                     = azurerm_subnet.db.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.20.3.4"
  }

  tags = {
    Environment = "Portfolio"
    Project     = "Secure-Azure-Infrastructure"
    ManagedBy   = "Terraform"
    Tier        = "Database"
  }
}

resource "azurerm_linux_virtual_machine" "db" {
  name                = "vm-db"
  resource_group_name = azurerm_resource_group.project.name
  location            = azurerm_resource_group.project.location
  size                = "Standard_F1als_v7"
  admin_username      = "azureadmin"
  depends_on = [
    azurerm_subnet_nat_gateway_association.db
  ]

  network_interface_ids = [
    azurerm_network_interface.db.id
  ]

  admin_ssh_key {
    username   = "azureadmin"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
#!/bin/bash
export DB_PASSWORD='${var.db_password}'
${file("${path.module}/scripts/db-setup.sh")}
EOF
  )

  tags = {
    Environment = "Portfolio"
    Project     = "Secure-Azure-Infrastructure"
    ManagedBy   = "Terraform"
    Tier        = "Database"
  }
}
