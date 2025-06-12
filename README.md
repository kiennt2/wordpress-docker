![alt text](https://raw.githubusercontent.com/kiennt2/wordpress-docker/refs/heads/master/banner.jpg)

This repository contains a Docker-based WordPress deployment solution.

It's designed to be production-ready with a focus on ease of installation and maintenance, includes well-documented
installation instructions and utility scripts for common maintenance tasks.

Support both development workflows and production deployments with minimal configuration required.

# Key Features

- [x] Complete Docker and Docker Compose setup for WordPress
- [x] Production-ready configuration with Nginx and SSL support
- [x] ModSecurity & Owasp CRS integration for enhanced security
- [x] Redis caching (for future use)
- [x] WordPress CLI integration for administrative tasks
- [x] Comprehensive backup and restore functionality (both disk and Git-based)
- [x] Automated SSL certificate renewal
- [x] Separate deployment scripts for local development and cloud environments

# Prerequisite

* [Docker & Docker Compose](https://docs.docker.com/engine/install/)
* [Linux-Postinstall - Run Docker without sudo](https://docs.docker.com/engine/install/linux-postinstall/)

# Installation

1. Clone the repository

    ```bash
   git clone https://github.com/kiennt2/wordpress-docker.git
   
   cd wordpress-docker
   
   git config core.filemode false
    ```

2. Create ```.env``` file

    ```bash
    cp .env.example .env
    ```

3. Edit the ```.env``` file to set your environment variables


4. Set executable permissions for the scripts ( assuming you are in the root project directory ):

    ```bash
    chmod -R a+x ./scripts
    chmod -R a+x ./deployment
    chmod a+x ./cli.sh
    chmod a+x ./composer.sh
    ```
   you may need to run the above command with `sudo` if you encounter permission issues.

### Local Development

```bash
bash ./deployment/local/one-time-setup.sh
```

### Cloud Deployment

```bash
bash ./deployment/cloud/one-time-setup.sh
```

### NOTE

You should run the one-time setup script only once, it will set up the initial environment and create necessary files
and directories.

Whenever you want to start or stop the containers, just navigate to the root project directory and run docker
commands, e.g.: ```docker compose up -d``` or ```docker compose down```.

# Backup Jobs

Depend on your needs, you can set up cron jobs for backup operations. Make sure cron is installed on your system.

1. If you prefer to save backup file to DISK & restore from DISK
    ```bash
    # Open crontab editor
    crontab -e    
    # Add this line to run backup-to-disk.sh daily at 12:00 PM (noon) - OR select the time you want to run the backup
    0 12 * * * bash /path/to/your-root-project/scripts/backup-to-disk.sh > /dev/null 2>&1    
    ```

2. If you prefer to save backup file to GIT & restore from GIT

   First, remove ```source``` and ```snapshot/wordpress_db.sql``` from the ```.gitignore``` file in the root project
   directory.

   By default, we ignore all files in the `source` directory and ```snapshot/wordpress_db.sql``` to prevent them from
   being committed to Git.

   ```bash
   # Open crontab editor
   crontab -e    
   # Add this line to run backup-to-git.sh daily at 12:00 PM (noon) - OR select the time you want to run the backup
   0 12 * * * bash /path/to/your-root-project/scripts/backup-to-git.sh > /dev/null 2>&1
   ```

The ```> /dev/null 2>&1``` will prevent logs to be saved. Change it to ```>> /path/to/your/logfile.log 2>&1``` if you
want to save logs to a file.

Make sure to replace ```/path/to/your-root-project``` with the actual full path to your project directory.

# Restores

1. If you choose DISK backup, you can restore from DISK by running:

    ```bash
    sudo bash /path/to/your-root-project/scripts/restore-from-disk.sh
    ```    
   Run the command above then select the backup file you want to restore from the list. By default, we save 14 days of
   backups. You can change this in the `scripts/backup-to-disk.sh` file by modifying the `MAX_BACKUPS` variable.


2. If you choose GIT backup, you can restore from GIT by running:

    ```bash
   sudo bash /path/to/your-root-project/scripts/restore-from-git.sh
    ```
   Run the command above then select the TAG NAME you want to restore from the list. You can select form list (default
   latest 10 Tags ) or type the tag name you want to restore from.

# Auto Renewal SSL

SSL certificates from Let's Encrypt expire every 90 days. To ensure your certificates are always valid, you can set up
an automatic renewal process:

```bash
# Open crontab editor
crontab -e

# Add this line to run the SSL renewal script monthly
0 0 1 * * bash /path/to/your-root-project/scripts/utils/renew-ssl.sh > /dev/null 2>&1
```

This will attempt to renew your SSL certificates on the first day of each month. Certificates will only be renewed if
they're close to expiration.

Make sure to replace ```/path/to/your-root-project``` with the actual path to your project directory.

# ModSecurity & Owasp CRS

Configuration files for ModSecurity and Owasp CRS are located in the `mod-security/conf` directory and mounted to
Docker. Feel free to apply your custom configurations.

```bash
- ./mod-security/conf/modsecurity.conf:/etc/nginx/modsecurity.conf
- ./mod-security/conf/owasp-crs/crs-setup.conf:/etc/nginx/owasp-crs/crs-setup.conf
- ./mod-security/conf/owasp-crs/rules:/etc/nginx/owasp-crs/rules
```

# WordPress CLI

```bash
./cli.sh <command>
# OR
bash ./cli.sh <command>
```

# Composer CLI

```bash
./composer.sh <command>
# OR
bash ./composer.sh <command>
# e.g.
# bash ./composer.sh require humanmade/s3-uploads
```

# Deal with permissions issues

```bash
bash ./fix_permissions.sh
```

# Reset Everything

If you want to reset everything and start over, you can run the following command:

```bash
bash /path/to/your-root-project/scripts/utils/reset-all.sh
```

Make sure to replace ```/path/to/your-root-project``` with the actual path to your project directory.

----------------------------------------------------

# Troubleshooting

----------------------------------------------------

> Unable to build for a platform ...

The error usually means that the platform (CPU architecture) your Docker image is being built for doesn't match the
platform of your host machine,
or that the base image you're using doesn't support the target platform.
This can happen when building for multiple architectures or when using base images that aren't available for all
platforms.

As you can see, we have 2 Dockerfiles inside the `mod-security` directory: `Dockerfile` and `amd64.Dockerfile`,

`Dockerfile` is for ARM64 architecture (Apple Silicon, Raspberry Pi, etc.) and `amd64.Dockerfile` is for AMD64
architecture (Intel/AMD processors).

Choose the right Dockerfile to build your image in `docker-compose.yml` file:

```bash
  ...
  webserver:
    depends_on:
      - wordpress
    build:
      context: ./mod-security
      dockerfile: Dockerfile  # OR amd64.Dockerfile
  ...
```

----------------------------------------------------

> Plugin caching_sha2_password could not be loaded

it usually happens when you import/export db via CLI, to fix it, you can run the following command:

1. ```docker ps -a``` to get the container ID of the MySQL container
2. ```docker exec -it <container_id> sh```
3. ```mysql -u root -p```
4. input your MySQL root password when prompted
5. ```ALTER USER 'user_same_as_env'@'%' IDENTIFIED WITH mysql_native_password BY 'user_password_same_as_env';```

----------------------------------------------------

> failed to create network wordpress-docker_app-network: Error response from daemon: Failed to program NAT chain: COMMAND_FAILED

I have encountered this issue when running Docker on a system with firewalld enabled (like AWS Linux 2).

The error indicates that Docker is unable to create the necessary network due to firewall rules.

Try this commands to fix the issue:

```bash
sudo firewall-cmd --permanent --zone=trusted --add-interface=docker0
sudo firewall-cmd --reload
docker compose up -d
```

NOTE: whenever you stop the containers, you may need to run the above commands again to fix the issue.

----------------------------------------------------

> Deploy on AWS Linux 2 uses AMD64 architecture

1. Install Docker

   Follow the [official Docker installation guide](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-docker.html).
   
   Run docker commands without `sudo`:

   ```bash
   sudo usermod -a -G docker ec2-user
   newgrp docker
   ```

2. Install Docker Compose

   ```bash
   sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/libexec/docker/cli-plugins/docker-compose
    ```
   
3. Docker Build

   You should use the `amd64.Dockerfile` to build the image for `webserver`. You should build the image on local machine:
   then push it to a Docker registry (like Docker Hub or AWS ECR) and pull it on the AWS instance. 

   Update the `docker-compose.yml` file to use the image from the registry, like this.

   ```bash
   ...
   webserver:
    depends_on:
      - wordpress
    image: mrkeyvn/wordpress-docker-webserver-amd64:latest
    container_name: webserver
   ...
   ```
