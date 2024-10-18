# Kimai Setup and Deployment to Ubuntu Server

## Prerequisites

- A server with freshly installed Ubuntu
- SSH access to your Ubuntu Server

## Step 1: Connect

1\. **Connect to Your Ubuntu Server**:
```sh
ssh user@YOUR-UBUNTU-SERVER-IP-ADDRESS
```

## Step 2: Install Docker on Your Ubuntu Server
1\. **Install Docker**:
```sh
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
```

2\. **Install Docker Compose**:
```sh
sudo apt-get install docker-compose-plugin
sudo curl -L "https://github.com/docker/compose/releases/download/v2.3.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

3\. **Add User to Docker Group**:
```sh
sudo usermod -aG docker $USER
newgrp docker
```

## Step 3: Generate SSH Key and Add to GitHub
1\. **Generate the SSH Key Pair on your Ubuntu Server**:
```sh
ssh-keygen -t ed25519 -C "your_email@example.com"
```

2\. **Add the Public Key to `authorized_keys`**:
```sh
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

3\. **Retrieve the Private Key**:
```sh
cat ~/.ssh/id_ed25519
```

4\. **Copy the content of the private key** to use in GitHub Secrets as SSH_PRIVATE_KEY.

5\. **Add the SSH Public Key to GitHub**:
```sh
cat ~/.ssh/id_ed25519.pub
```
- Go to GitHub and log in to your account.
- In the upper-right corner of any page, click your profile photo, then click **Settings**.
- In the user settings sidebar, click **SSH and GPG keys**.
- Click **New SSH key**.
- In the "Title" field, add a descriptive label for the new key.
- Paste your key into the "Key" field.
- Click **Add SSH key**.
- Confirm your GitHub password if prompted.

## Step 4: Install and Configure Caddy

### Install Caddy

```sh
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install -y caddy
```

### Configure Caddy

```sh
sudo vim /etc/caddy/Caddyfile
```

Add the following configuration:

```caddyfile
kimai.donce.dev {
        tls adom.donatas@gmail.com
        request_body {
                max_size 100MB
        }
        reverse_proxy 127.0.0.1:8001
}
```

**Restart Caddy:**

```sh
sudo systemctl restart caddy
```

Check the Caddy service status:

```sh
sudo systemctl status caddy
```

## Step 4: Backups

1\. **Make the scripts executable in the kimai-tracker project directory**:
```sh
sudo chmod +x ./backup-scripts/backup.sh ./backup-scripts/list_backups.sh ./backup-scripts/restore_backup.sh
```

2.1\. **Create backups dir in the kimai-tracker project directory**:
```sh
sudo mkdir -p ./backups
```

2.2\. **Change ownership and permissions of the ./backups directory in the kimai-tracker project directory**:
```sh
sudo chown -R dondoncece:sudo ./backups
sudo chmod -R 755 ./backups
```

3\. **Set up a cron job for root user to run the backup script daily at night**:
```sh
sudo crontab -e
```

Add the following line to the crontab file to run the backup script every day at 2 AM:
```sh
0 2 * * * /bin/bash /home/dondoncece/kimai-tracker/backup-scripts/backup.sh
```

## Step 5: Running Backup Scripts
1\. **Run `backup.sh`**:
```sh
sudo -E ~/kimai-tracker/backup-scripts/backup.sh
```
This script creates a backup of the Kimai tracker and stores it in the `/backups` directory. It also removes backups older than 30 days.

2\. **Run `list_backups.sh`**:
```sh
~/kimai-tracker/backup-scripts/list_backups.sh
```
This script lists all available backups in the `/backups` directory.

3\. **Run `restore_backup.sh`**:
```sh
sudo -E ~/kimai-tracker/backup-scripts/restore_backup.sh <backup-name-with-full-path>
```
Replace `<backup-name>` with the name of the backup file you want to restore. This script restores the specified backup.

## Step 6: After Server Setup You Can Deploy Repo via Github

1\. **Add Secrets to GitHub**:
- Go to your GitHub repository.
- Navigate to `Settings` > `Secrets and variables` > `Actions`.
- Add the following secrets:
- `SSH_PRIVATE_KEY`: Your private SSH key.
- `UBUNTU_SERVER_IP`: Your Ubuntu Server IP address.
- `DATABASE_NAME`: The name of your MongoDB database.
- `DATABASE_USER`: The username for your MongoDB database.
- `DATABASE_PASSWORD`: The password for your MongoDB database user.
- `DATABASE_ROOT_PASSWORD`: The root password for your MongoDB instance.
- `ADMIN_EMAIL`: The email address for the admin user of your application.
- `ADMIN_PASSWORD`: The password for the admin user of your application.

These secrets are used in the GitHub Actions workflow to securely deploy your application and set up the database environment.

2\. **Now You Can Commit Changes to the Github Repository and Deploy it should automatically deploy to Ubuntu Server**

3\. **After Deployment You Can Check the Service Status with this Command Inside of Ubuntu Server**
```sh
docker service ls
```

## Step 7: Install Yacht

Install Yacht via Docker https://github.com/SelfhostedPro/Yacht

You must use selfhostedpro/yacht:devel
```sh
docker volume create yacht
docker run -d --name yacht -p 8000:8000 --restart unless-stopped -v /var/run/docker.sock:/var/run/docker.sock -v yacht:/config selfhostedpro/yacht:devel
```

Now you can access Yacht via UBUNTU_SERVER_IP_ADDRESS:8000

After installing Yacht change admin@yacht.local password

### Summary

1\. **Install Docker** on your Ubuntu Server.
2\. **Generate an SSH key pair and add the public key to your GitHub account**.
3\. **Create backup, list backups, and restore backup scripts** and set up a cron job for daily backups.
4\. **Run backup scripts** to manage Kimai backups.
5\. **Update GitHub Actions Workflow** to handle the deployment process.
6\. **Install Yacht - Docker Container Management UI**.
