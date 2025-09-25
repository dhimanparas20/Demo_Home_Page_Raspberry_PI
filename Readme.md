# Simple Deploy on Your Pi

This guide will help you set up a server on your Raspberry Pi or Ubuntu server with Docker and Docker Compose along with a free domain and port forwarding.

## Steps:

### 1. Set up your Pi/Server
- Use the following script to set up your server:

```bash
https://raw.githubusercontent.com/dhimanparas20/Useful-Scripts/refs/heads/main/Shell%20Scripts/MAIN_UBUNTU_SERVER_INSTALL_SETUP.sh
```

Note: ``Make sure Docker and Docker Compose are installed on your Pi/Server.``

### 2. Get a Domain
- Register a domain using [No-IP](https://my.noip.com/). This service will help you map a dynamic IP to a domain.

### 3. Set up Dynamic DNS (DDNS)
- Configure DDNS in your [router settings](http://192.168.1.1) to automatically update your dynamic IP every hour, or use the script/software provided by No-IP to do this.

### 4. Set Port Forwarding
- In your router settings, enable port forwarding or DMZ (Demilitarized Zone) to forward traffic to your Pi/Server's static IP. Ensure that the IP address of your Pi/Server is set to static.

### 5. Clone the Repo
- Clone [this repository](https://github.com/dhimanparas20/Demo_Home_Page) to your Pi/Server:

```bash
git clone https://github.com/dhimanparas20/Demo_Home_Page
```
### 6. Configure docker-compose.yml
- Make sure to configure the [docker-compose](compose.yml) file as needed for your setup.

### 7. Run the Application
- Once everything is set up, run the following command to start the application:

``` bash
sudo docker compose up --build -d
```
8. Enjoy Your Home Server!
- Your server is now set up and running at your home. Access it via your domain, and you're all set!

## GitHub CI/CD Pipeline:
*This project also supports a GitHub CI/CD pipeline for automated deployment. Follow these steps to set it up:*

### 1. Set up GitHub Secrets:
In your GitHub repository, go to ``Settings > Security > Secrets and Variables > Actions `` & add the following Repository secrets:
- ``SSH_USER``: The SSH username.
- ``SSH_HOST``: The SSH host.
- ``SSH_PASSWORD``: The password for SSH authentication (you can store this securely in GitHub Secrets).
- ``WORK_DIR``: The working directory where you want to run the commands.
- ``MAIN_BRANCH``: The main branch name (e.g., main or master).

### 2. CI/CD Workflow:
After adding the secrets, the pipeline will be triggered on each push or manual trigger to deploy the updates to your Pi/Server automatically.

## Auto IP updation to Non Static IP providing ISP Users
- Just visit [This repo](https://github.com/dhimanparas20/dynamic_dns_updater). It will guide you how to setup stuff
- #prostuff use [This service](https://github.com/dhimanparas20/Room_Automation_CI-CD_Deploy/blob/main/compose.yml#L41) to use lazydocker web instead of portainer

The pipeline will:
- Pull the latest changes from your GitHub repository.
- Build the Docker image.
- Deploy the application using Docker Compose.
