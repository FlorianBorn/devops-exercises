# Terraform Standard Module Structure
https://developer.hashicorp.com/terraform/language/modules/develop/structure  

/  (root Module)  
    main.tf  
    variables.tf  
    outputs.tf  
modules/  
    --> hier nested modules  
    nestedModuleA/  
        main.tf  
        variables.tf  
        outputs.tf  

Jedes Terraform Projekt (jede Terraform Konfiguration) hat mind. ein Module, das auch als Root Module bekannt ist.

Ein Module kann auch andere Module aufrufen. Des aufgerufene Module wird dann als Child Module bezeichnet.
    Ein Child Module kann auch mehrfach aufgerufen werden

# Anforderungen 
- das VPC soll "my_vpc" heißen
- dem VPC soll folgendes Netz zugewiesen werden "172.125.0.0/16"
- das VPC verfügt über 1 public und ein private subnet
- das Public Subnet hat das Netz 172.125.1.0/24
- das Private Subnet hat das Netz 172.125.2.0/24
- Es gibt eine EC2 Instanz im private Subnetz, die Internetzugriff hat
- jede Ressource soll mit tags versehen werden

# Terraform ausrollen
terraform init # einmalig
terraform fmt
terraform plan
terraform apply