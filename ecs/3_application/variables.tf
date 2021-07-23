variable "region" {
    default = "eu-west-1"
    description = "AWS Region"
}

variable "remote_state_key" {
  
}

variable "remote_state_bucket" {
  
}

# Application variables

variable "backend_task_definition_name" {
  
}

variable "backend_service_name" {
  
}

variable "backend_docker_image_url" {
  
}
variable "memory" {
  
}

variable "backend_docker_container_port" {
  
}

variable "app_settings" {
  
}

variable "database_url" {
  
}

variable "redis_url" {
  
}

variable "broker_url" {
  
}

variable "days_old_media_delete" {
  
}

variable "desired_task_number" {
  
}

variable "frontend_task_definition_name" {
  
}

variable "frontend_docker_image_url" {
  
}

variable "backend_internal_url" {
  
}

variable "backend_public_url" {
  
}

variable "frontend_docker_container_port" {
  
}

variable "frontend_service_name" {
  
}

# Worker variables

variable "worker_task_definition_name" {
  
}

# DB variables

variable "db_task_definition_name" {
  
}

variable "db_docker_image_url" {
  
}

variable "db_database" {
  
}

variable "db_password" {
  
}

variable "db_user" {
  
}

variable "db_port" {
  
}

# Redis variables

variable "redis_task_definition_name" {
  
}

variable "redis_docker_image_url" {
  
}

variable "redis_port" {
  
}

# Rabbit variables

variable "rabbit_task_definition_name" {
  
}

variable "rabbit_docker_image_url" {
  
}

variable "rabbit_user" {
  
}

variable "rabbit_pass" {
  
}

variable "rabbit_port" {
  
}
