prefix             = "jenkins"
instance_type      = "t3a.micro"
ssh_user           = "ec2-user"
user_data_template = "templates/jenkins_server.tpl"

user_data = [
  "YOUR_SSH_KEY",
]
