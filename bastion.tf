resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = "rg-secure-infra"
  virtual_network_name = "vnet-secure-infra"
  address_prefixes     = ["10.20.20.0/26"]
}

resource "azurerm_public_ip" "bastion" {
  name                = "pip-secure-bastion"
  location            = "eastus"
  resource_group_name = "rg-secure-infra"
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name                = "bas-secure-infra"
  location            = "eastus"
  resource_group_name = "rg-secure-infra"
  sku                 = "Basic"

  ip_configuration {
    name                 = "bastion-ipconfig"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}