output "client_public_ip" {
	value	= aws_instance.client_instance.public_ip
}

output "vpn-server_public_ip" {
	value	= aws_instance.vpn_server_instance.public_ip
}

resource "local_file" "AnsibleInventory" { 
    content = templatefile("inventory.tmpl", 
    {  
		client_ip = aws_instance.client_instance.public_ip,
		client_id = aws_instance.client_instance.id,  
		vpn-server_ip = aws_instance.vpn_server_instance.public_ip,
		vpn-server_id = aws_instance.vpn_server_instance.id
    } ) 
    filename = "../ansible/inventory"
}