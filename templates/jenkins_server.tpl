Content-Type: multipart/mixed; boundary="//"
MIME-Version: 1.0

--//
Content-Type: text/cloud-config; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="cloud-config.txt"

#cloud-config
cloud_final_modules:
- [scripts-user, always]

--//
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="userdata.txt"

#!/bin/bash
JENKINS_HOME=/srv/jenkins

if [[ "$HOSTNAME" == "jenkins-server" ]]; then
  echo "Run once scripts already executed, exiting"
else
  #Set Server hostname
  hostnamectl set-hostname jenkins-server

  #Verify mongoDB mount point
  printf "\nCreating volume directory...\n"
  sudo mkdir -p /srv/jenkins

  #Install Docker and Docker Compose
  sudo yum update -y
  sudo amazon-linux-extras install docker -y
  sudo sh -c 'curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose'
  sudo chmod +x /usr/local/bin/docker-compose
  sudo usermod -aG docker ec2-user

  #Configure ssm-agent
  sudo systemctl enable amazon-ssm-agent
  sudo systemctl status amazon-ssm-agent

  #Enable and start Docker
  sudo systemctl start docker
  sudo systemctl enable docker

fi

#Docker compose file to run Jankins container
sudo sh -c "cat << EOF > $JENKINS_HOME/docker-compose.yaml
---
version: '3.8'
services:
  jenkins:
    image: 'jenkins/jenkins:2.60.3-alpine'
    container_name: 'jenkins'
    privileged: true
    user: root
    ports:
      - '80:8080'
      - '50000:50000'
    volumes:
      - '$JENKINS_HOME:/var/jenkins_home'
      - '/var/run/docker.sock:/var/run/docker.sock'
EOF"

#Execute docker compose to run GitLab container
cd $JENKINS_HOME && sudo /usr/local/bin/docker-compose up -d

##
## Custom user data
##
cat <<"__EOF__" >/home/${ssh_user}/.ssh/authorized_keys
${user_data}
__EOF__

echo 'Done Initialization Template'
