# Terraform init
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}
# Docker setup
provider "docker" {
	host = "unix:///var/run/docker.sock"
}
# Variables setup
resource "docker_volume" "uploads" {
  name = "uploads_vol"
}

resource "docker_volume" "outputs" {
  name = "outputs_vol"
}

# Docker networks setup
resource "docker_network" "metrics_network" {
	name = var.inner_network.name
}

resource "docker_network" "rabbitmq_network"{
    name = var.rabbitmq_network.name
}
#Docker images setup
resource "docker_image" "backend" {    
    name = "back"
    build {
        context = "../containers/backend/"
    }

}

resource "docker_image" "worker" {
    name = "work"
    build {
        context = "../containers/worker/"
    }
}
# Docker containers launch
resource "docker_container" "cadvisor" {
  name  = var.cadvisor.container_name
  image = "gcr.io/cadvisor/cadvisor:latest"

  volumes {
    host_path      = "/"
    container_path = "/rootfs"
    read_only      = true
  }

  volumes {
    # Mount Docker's container info
    host_path      = "/var/run"
    container_path = "/var/run"
    read_only      = false
  }

  volumes {
    host_path      = "/sys"
    container_path = "/sys"
    read_only      = true
  }

  volumes {
    host_path      = "/var/lib/docker"
    container_path = "/var/lib/docker"
    read_only      = true
  }

  ports {
  	internal = 8080
	external = var.cadvisor.port
  }
  networks_advanced {
   name = docker_network.metrics_network.name
   aliases = [var.cadvisor.network_name]
  }

  restart = "unless-stopped"
}
#
# Here goes config generation code
#
resource "docker_container" "rabbitmq" {
 name = var.rabbitmq.container_name
 image = "rabbitmq:3-management"

 ports {
 	internal = 15672
 	external = var.rabbitmq.port
 }

 networks_advanced {
	name = docker_network.metrics_network.name
	aliases = [var.rabbitmq.network_name]
 }
 networks_advanced {
	name = docker_network.rabbitmq_network.name
	aliases = [var.rabbitmq.network_name]
 }
 env = [
	"RABBITMQ_DEFAULT_USER=${var.rabbitmq.login}",
	"RABBITMQ_DEFAULT_PASS=${var.rabbitmq.password}"
 ]
}

resource "docker_container" "prometheus" {
 name  = var.prometheus.container_name
 image = "prom/prometheus"

 ports {
 	internal = 9090
	external = var.prometheus.port
 }

 volumes {
 	host_path = abspath(var.prometheus.config_path)
	container_path = "/etc/prometheus/prometheus.yml"
 }

  networks_advanced {
   name = docker_network.metrics_network.name
   aliases = [var.prometheus.network_name]
  }
}

resource "docker_container" "grafana" {
 name = var.grafana.container_name
 image = "grafana/grafana"

 ports {
 	internal = 3000
	external = var.grafana.port
 }
 # add auto dashboard add
 networks_advanced{
   name = docker_network.metrics_network.name
   aliases = [var.grafana.network_name]
 	
 }
 volumes {
    host_path      = "${abspath(var.grafana.datasource_folder)}"
    container_path = "/etc/grafana/provisioning/datasources"
    read_only      = true
  }

 volumes {
    host_path      = "${abspath(var.grafana.dashboard_config_folder)}"
    container_path = "/etc/grafana/provisioning/dashboards"
    read_only      = true
  }

  volumes {
    host_path      = "${abspath(var.grafana.dashboards_folder)}"
    container_path = "/var/lib/grafana/dashboards"
    read_only      = true
  }
  env = [
    "GF_SECURITY_ADMIN_USER=${var.grafana.admin_login}",
    "GF_SECURITY_ADMIN_PASSWORD=${var.grafana.admin_password}"
  ]
}

resource "docker_container" "backend" {
    image = docker_image.backend.name
    name = var.backend.name
volumes {
    volume_name    = docker_volume.uploads.name
    container_path = "/app/uploads"
  }
  volumes {
    volume_name    = docker_volume.outputs.name
    container_path = "/app/outputs"
  }
    ports {
        internal = 5000
        external = var.backend.port
    }
    networks_advanced {
	    name = docker_network.rabbitmq_network.name
	    aliases = [var.rabbitmq.network_name]
    }
    env = [
        "RABBITMQ_HOST=${var.rabbitmq.network_name}",
        "RABBITMQ_PORT=5672",
        "RABBITMQ_USER=${var.rabbitmq.login}",
        "RABBITMQ_PASSWORD=${var.rabbitmq.password}"
    ]
}

resource "docker_container" "worker" {
    count = var.container_amount
    image = docker_image.worker.name
    name = "worker-${count.index}"
volumes {
    volume_name    = docker_volume.uploads.name
    container_path = "/app/uploads"
  }
  volumes {
    volume_name    = docker_volume.outputs.name
    container_path = "/app/outputs"
  }
    networks_advanced {
	    name = docker_network.rabbitmq_network.name
	    aliases = [var.rabbitmq.network_name]
    }  
    env = [
        "RABBITMQ_HOST=${var.rabbitmq.network_name}",
        "RABBITMQ_PORT=5672",
        "RABBITMQ_USER=${var.rabbitmq.login}",
        "RABBITMQ_PASSWORD=${var.rabbitmq.password}"
    ]
}
