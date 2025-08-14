variable "container_amount" {
	description = "Amount of docker container to launch"
	type 	    = number
	default	    = 3
}

variable "inner_network" {
	type = object({
	    name = string
	})
	default = {
		name = "inner_network"
	}
}

variable "prometheus" {
	type	    = object({
		container_name = string
		port = number
		config_path = string
		update_time = string
		network_name = string
	})
    sensitive = true
	default	    = {
		container_name = "prometheus-0"
		port = 9090
		config_path = "../prometheus/prometheus.yml"
		update_time = "5s"
		network_name = "prometheus"
	}
}

variable "grafana" {
	type	    = object({
		container_name = string
		port = number
		datasource_folder = string
		dashboard_config_folder = string
		dashboards_folder = string
		network_name = string
		admin_login = string
		admin_password = string
	})
    sensitive = true
	default	   = {
		container_name = "grafana-0"
		port = 3000
		datasource_folder = "../grafana/datasources"
		dashboard_config_folder = "../grafana/dashboard_config"
		dashboards_folder = "../grafana/dashboards"
		network_name = "grafana"
		admin_login = "login"
		admin_password = "password"
	}
}

variable "cadvisor" {
	type = object({
		port = number
		container_name = string
		network_name = string
	})
    sensitive = true
	default = {
		port = 8080
		container_name = "cadvisor-0"
		network_name = "cadvisor"
	}
}

variable "rabbitmq_network"{
    type = object({
        name = string
})
    default = {
        name = "rabbitmq"
}
}

variable "backend" {
    type = object({
        port = number
        name = string
})
    default = {
        port = 5000
        name = "backend-0"
    }
}

variable "rabbitmq" {
	type = object({
		port = number
		container_name = string
		network_name = string
		login = string
		password = string
	})
    sensitive = true
	default = {
		port = 15672
		container_name = "rabbitmq-0"
		network_name = "rabbitmq"
		login = "login"
		password = "password"
	}
}
