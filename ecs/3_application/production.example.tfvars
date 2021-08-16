# remote state conf
remote_state_key = "PROD/platform.tfstate"
remote_state_bucket = "delta-reporter-tf-remote-state"

# backend service variables
backend_task_definition_name = "delta-backend"
backend_service_name = "core"
backend_docker_container_port = 5000
desired_task_number = "1"
app_settings = "config.ProductionConfig"
database_url = "postgresql://delta:murcielago@127.0.0.1:5432/delta_db"
redis_url = "redis://127.0.0.1:6379/0"
broker_url = "amqp://delta:123123@127.0.0.1:5672//"
days_old_media_delete = "3"
memory = 512
cpu = 256
frontend_memory = 1024
frontend_cpu = 256

# worker service variables
worker_task_definition_name = "delta-worker"

# frontend service variables
frontend_task_definition_name = "delta-frontend"
frontend_docker_image_url = "deltareporter/delta_frontend:version1.27.3"
backend_internal_url = "https://.org"
backend_public_url = "https://.org"
frontend_docker_container_port = 3000
frontend_service_name = "demo"

# db service variables
db_task_definition_name = "delta-db"
db_docker_image_url = "postgres:12"
db_database = "delta_db"
db_password = "murcielago"
db_user = "delta"
db_port = "5432"

# redis service variables
redis_task_definition_name = "delta-redis"
redis_docker_image_url = "redis:6.2"
redis_port = 6379

# rabbit service variables
rabbit_task_definition_name = "delta-rabbit"
rabbit_docker_image_url = "rabbitmq:3.8"
rabbit_user = "delta"
rabbit_pass = "123123"
rabbit_port = 5672
