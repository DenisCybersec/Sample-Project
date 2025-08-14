# Sample project

This project sets up a scalable background removal service using Docker containers managed by Terraform. It includes a Flask backend, worker nodes, RabbitMQ queue, and a full monitoring stack (Prometheus, Grafana, cAdvisor).

## Features
- Image uploads via web interface
- Background removal using MediaPipe
- Worker containers with changeable amount 
- Performance monitoring with Prometheus/Grafana (Upcoming)
- Container metrics via cAdvisor
- RabbitMQ task queue management

## Prerequisites
1. [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
2. [Docker](https://docs.docker.com/get-docker/)

## Setup Instructions
### 0. Clone the project 
```bash
git clone https://github.com/DenisCybersec/Sample-Project
cd Sample-Project
```
### 1. Initialize Terraform

```bash
cd terraform/
terraform init
```

### 2. Start the infrastructure
```bash
terraform apply
```

### 3. Access services:
| Service      | URL                          | Default Credentials     |
|--------------|------------------------------|-------------------------|
| Backend      | http://localhost:5000        | None                    |
| RabbitMQ     | http://localhost:15672       | login:password          |
| Grafana      | http://localhost:3000        | login:password          |
| Prometheus   | http://localhost:9090        | None                    |
| cAdvisor     | http://localhost:8080        | None                    |

## Configuration
Modify `variables.tf` for custom settings:

⚠️Change default login and password for Grafana and RabbitMQ⚠️

## Monitoring
Grafana is preconfigured with:
   - Docker monitoring dashboard
   - RabbitMQ queue metrics (Upcoming)
   - Image processing performance stats (Upcoming)

## Application Structure
```
├── containers                  # Docker containers folder
│   ├── backend                 # Flask app
│   │   ├── backend.py
│   │   ├── Dockerfile
│   │   ├── requirements.txt
│   │   └── templates
│   │       ├── index.html
│   │       └── result.html
│   └── worker                  # Image processing app
│       ├── Dockerfile
│       ├── requirements.txt
│       └── worker.py
├── grafana                     # Grafana configs folder
│   ├── dashboard_config
│   │   └── dashboards.yml
│   ├── dashboards
│   │   └── dashboard.json
│   └── datasources
│       └── datasources.yml
├── prometheus                  # Prometheus config folder
│   └── prometheus.yml                   
├── terraform                   # Terraform config folder
│   ├── main.tf
│   └── variables.tf
└── ReadMe.md                   # You are reading it right now :)
```

## Key Components
### Backend (Flask App)
- Handles file uploads
- Manages task queueing
- Serves processed images

### Worker
- Processes images using OpenCV and MediaPipe
- Listens to RabbitMQ tasks
- Writes processing metrics

### Monitoring Stack
- **Prometheus**: Metrics collection
- **Grafana**: Visualization dashboards
- **cAdvisor**: Container resource monitoring
