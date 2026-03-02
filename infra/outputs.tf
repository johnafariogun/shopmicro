resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"
  content  = <<-EOF
    [masters]
    master ansible_host=${module.compute.master_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/${var.key_name}.pem

    [workers]
    worker_data ansible_host=${module.compute.worker_data_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/${var.key_name}.pem k8s_role=data k8s_tier=data k8s_taint="data-only=true:NoSchedule"
    worker_backend ansible_host=${module.compute.worker_backend_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/${var.key_name}.pem k8s_role=app k8s_tier=app
    worker_frontend ansible_host=${module.compute.worker_frontend_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/${var.key_name}.pem k8s_role=frontend k8s_tier=frontend
    worker_ml ansible_host=${module.compute.worker_ml_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/${var.key_name}.pem k8s_role=ml-service k8s_tier=ml-service
    worker_runner ansible_host=${module.compute.worker_runner_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/${var.key_name}.pem k8s_role=runner
    
    [cluster:children]
    masters
    workers
  EOF
}