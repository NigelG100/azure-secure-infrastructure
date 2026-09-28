output "web_public_ip" {
  description = "Public IP address of the web server"
  value       = azurerm_public_ip.web.ip_address
}

output "web_url" {
  description = "URL for the NGINX web server"
  value       = "http://${azurerm_public_ip.web.ip_address}"
}

output "resource_group_name" {
  description = "Resource group containing the infrastructure"
  value       = azurerm_resource_group.project.name
}

output "web_vm_name" {
  description = "Name of the web virtual machine"
  value       = azurerm_linux_virtual_machine.web.name
}

