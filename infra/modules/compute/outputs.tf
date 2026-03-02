output "master_ip" { value = aws_instance.master.public_ip }
output "worker_data_ip" { value = aws_instance.worker_data.public_ip }
output "worker_backend_ip" { value = aws_instance.worker_backend.public_ip }
output "worker_frontend_ip" { value = aws_instance.worker_frontend.public_ip }
output "worker_ml_ip" { value = aws_instance.worker_ml.public_ip }
output "worker_runner_ip" { value = aws_instance.worker_runner.public_ip }