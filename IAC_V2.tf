provider "openstack" {
  user_name   = "admin"
  tenant_name = "admin"
  password    = "123123"
  auth_url    = "http://10.0.0.11:5000/v3"
  region      = "RegionOne"
  domain_name = "default"
}

#Here we create a router with external_gateway -------------

resource "openstack_networking_router_v2" "router_terraform" {
 name                = "router_terraform"
  admin_state_up      = true
  external_network_id = "bfd56918-cfab-4d06-a5b3-c890f2ac648b"
}


#Here we create an internal network --------------------

resource "openstack_networking_network_v2" "internal_terraform" {
  name           = "internal_terraform"
  admin_state_up = "true"
}

# Her we got 4 floatings IPs

resource "openstack_networking_floatingip_v2" "float_1" {
  pool = "provider"
  count = 2
  region = "RegionOne"
}
resource "openstack_networking_floatingip_v2" "float_2" {
  pool = "provider"
  count = 2
  region = "RegionOne"
}

#Here we associate this subnet to the "internal_terraform"-----------------

resource "openstack_networking_subnet_v2" "subnet_1_Terraform" {
  name       = "subnet_1_Terraform"
  network_id = "${openstack_networking_network_v2.internal_terraform.id}"
  cidr       = "172.1.2.0/24"
  ip_version = 4
  enable_dhcp = "true"
  depends_on =["openstack_networking_network_v2.internal_terraform"]
}

#Here we create an interface associated between router and network----------

resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = "${openstack_networking_router_v2.router_terraform.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_1_Terraform.id}"
  depends_on= ["openstack_networking_subnet_v2.subnet_1_Terraform"]
  depends_on =["openstack_networking_router_v2.router_terraform"]
}

resource "openstack_compute_instance_v2"  "Web_Server_" {
	count = 2
	name = "Web_Server_${count.index}"
	image_id = "b4d7009f-5071-46c8-b16d-5f38e2589aef"
	flavor_id = "0"
	security_groups = ["default"]
	
		  network {
	  
		name = "internal_terraform"
	}
	
	depends_on=["openstack_networking_subnet_v2.subnet_1_Terraform"]
}
resource "openstack_compute_instance_v2"  "Load_Balancer_Server" {
	name = "Load_Balancer_Server"
	image_id = "b4d7009f-5071-46c8-b16d-5f38e2589aef"
	flavor_id = "0"
	security_groups = ["default"]
	
		  network {
	  
		name = "internal_terraform"
	}
	depends_on=["openstack_networking_subnet_v2.subnet_1_Terraform"]
}
#Here we create a second internal network --------------------

resource "openstack_networking_network_v2" "internal_terraform_2" {
  name           = "internal_terraform_2"
  admin_state_up = "true"
}
#Here we associate this subnet to the "internal_terraform_2"-------------------------

resource "openstack_networking_subnet_v2" "subnet_2_Terraform" {
  name       = "subnet_2_Terraform"
  network_id = "${openstack_networking_network_v2.internal_terraform_2.id}"
  cidr       = "10.20.30.0/24"
  ip_version = 4
  enable_dhcp = "true"
  depends_on=["openstack_networking_network_v2.internal_terraform_2"]
}

#Here we create an interface associated between router and network-------------------------

resource "openstack_networking_router_interface_v2" "router_interface_2" {
  router_id = "${openstack_networking_router_v2.router_terraform.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_2_Terraform.id}"
  depends_on= ["openstack_networking_subnet_v2.subnet_2_Terraform"]
  depends_on =["openstack_networking_router_v2.router_terraform"]
  
}

resource "openstack_compute_instance_v2"  "DB_Server_" {
	count = 2
	name = "DB_Server_${count.index}"
	image_id = "b4d7009f-5071-46c8-b16d-5f38e2589aef"
	flavor_id = "0"
	security_groups = ["default"]
	
		  network {
	  
		name = "internal_terraform_2"
	}
	depends_on =["openstack_networking_subnet_v2.subnet_2_Terraform"]
}

resource "openstack_compute_floatingip_associate_v2" "fip_1" {
	region      = "RegionOne"
	count = 2
  floating_ip = "${element(openstack_networking_floatingip_v2.float_1.*.address,count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.Web_Server_.*.id,count.index)}"
  depends_on=["openstack_compute_instance_v2.Web_Server_"]
  depends_on=["openstack_networking_floatingip_v2.float_1"]
}
resource "openstack_compute_floatingip_associate_v2" "fip_2" {
	region      = "RegionOne"
	count = 2
  floating_ip = "${element(openstack_networking_floatingip_v2.float_2.*.address,count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.DB_Server_.*.id,count.index)}"
  depends_on=["openstack_compute_instance_v2.DB_Server_"]
  depends_on=["openstack_networking_floatingip_v2.float_2"]
}