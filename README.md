====================================================
Overview
====================================================

This repository mantains the code for deploying the TranSappVisualization server on a linux machine, which means:
- Step 1: linux user creation
- Step 2: dependencies installation
- Step 3: postgresql configuration
- Step 4: clone and setup of the django app
- Step 5: apache configuration


====================================================
Prerequisites for visualization server
====================================================

## Linux Machine with Ubuntu 16.04

This has been tested on Ubuntu 16.04 machines.


## Superuser privileges

The installation script requires sudo access.


## Account Creation     

To create a linux user run the command `adduser <user_name>`. After that you should see the next messages

```
Adding user `<user_name>' ...
Adding new group `<user_name>' (1000) ...
Adding new user `<user_name>' (1000) with group `visualization' ...
Creating home directory `/home/<user_name>' ...
Copying files from `/etc/skel' ...
Enter new UNIX password:
Retype new UNIX password:
passwd: password updated successfully
Changing the user information for <user_name>
Enter the new value, or press ENTER for the default
        Full Name []:
        Room Number []:
        Work Phone []:
        Home Phone []:
        Other []:
Is the information correct? [Y/n] Y
```

====================================================
Passwordless SSH Authentication (on TranSapp app server)
====================================================

## Required Keys

To be able to install this server, you will require to have ssh access from the TranSapp app server.

First, you need to generate keys for your root user:
```bash
# rsa encription, no passphrase, filename
$ ssh-keygen -t rsa -N "" -f "/root/.ssh/id_rsa"
```

Copy and paste the generated `.pub` key (`/root/.ssh/id_rsa.pub`) for root into the `/home/<user>/.ssh/authorized_keys`on the visualization server, where `<user>` **relates to the user created while installing.**. To move ssh key to TranSapp visualization server you can use `ssh-copy-id` command.
```bash
sudo -u root ssh-copy-id -i /root/.ssh/id_rsa <user>@<ip>
```
Then, try to perform a ssh connection to the TranSapp visualization server, using the generated private key. Just accept when prompted whether to accept the fingerprint on this first connection.
```bash
sudo -u root ssh -i /root/.ssh/id_rsa <user>@<ip>
```
You should see something like this
```
The authenticity of host '<ip> (<ip>)' can't be established.
ECDSA key fingerprint is xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '<ip>' (ECDSA) to the list of known hosts.
```

Note, you may need to install the `openssh-server` debian package on both machines.
```bash
$ sudo apt-get install openssh-server
```
====================================================
Prepare a Database Dump (on TranSapp app server)
====================================================

## Database dump file

The installation process requires a database dump from the TranSapp server, with the `AndroidRequests` models and `django_migrations` table will be ok and migration files:

```bash
## ON TranSapp app server
# perform dump
sudo -u postgres pg_dump <database_name> > dump.sql
# compress 
$ tar -zcvf dump.sql.tar.gz dump.sql
# send using the previous generated key
$ scp -i /root/.ssh/id_rsa  dump.sql.tar.gz <user>@<ip>:<destination_folder>

# perform backup and compresion of migration files  
tar -zcvf migrations.tar.gz -C <path_to_project>/AndroidRequests/migrations/ .
# send to TranSapp Visualization server
scp -i /root/.ssh/id_rsa migrations.tar.gz <user>@<ip>:<destination_folder>

## ON TranSapp Visualization server
# uncompress sql dump
cd <destination_folder>
tar -zxvf dump.sql.tar.gz

# OBS: migrations tar file will be uncompress by installation script
```

====================================================
DEPLOYMENT
====================================================

## Clone the the installer

```bash
# clone directly on the target machine
$ git clone https://github.com/InspectorIncognito/visualizationServerInstaller.git

# or download anywhere and then copy the files to the visualization server:
# e.g. if you want to bring up an AWS EC2 with ubuntu OS:
$ scp -i <private_key> -r install <server-user>@<server-host>:/home/<server-user>
```

## Modify it with the missing Django key

The django app needs a secret key, you can [generate a new one](http://www.miniwebtool.com/django-secret-key-generator/) and manually replace the `<INSERT_DJANGO_SECRET_KEY>` script variable on `installScript.sh`. But, if you are lazy just run the next instruction: `sed -i 's/<INSERT_DJANGO_SECRET_KEY>/<MY_DJANGO_SECRET_KEY>/g' <path_to_project>/visualizationServerInstaller/installScript.sh`


## Understanding the installer

You need the following information:
- `<SERVER_PUBLIC_IP>`: This server public IP, used in apache configuration file
- `<DATABASE_NAME>`: name of the new database
- `<POSGRES_USER>`: name of the new postgres user
- `<POSTGRES_USER_PASS>`: postgres user's pasword
- `<DUMP_DB_PATH>`: full path to a DB dump (.sql file), obtained from the TranSapp App database
- `<MIGRATIONS>`: full path of the migrations .tar.gz from TranSapp App django application
- `<LINUX_USER_NAME>`: linux user name used to choose the folder where TranSapp visualization project will be located


It is highly recommended to read the script before running it and ALSO EXECUTTE IT BY ONE PIECE AT A TIME!. Modify the configuration section on `installScript.sh` to select which steps do you want to run. The recommended way is to deactivate all steps and run them separately. 

Inside `installScript.sh` you will discover 5 steps:
1. Clone project: clone django visualization server project
2. install packages: install project dependencies
3. Postgresql configuration: create database and load data to it
4. Project configuration: 
5. Apache_configuration

## Known Problems

### Missing files when calling manage.py (step 4 Project configuration)

The visualization server requires the `admins.json`, `email_config.json` and `android_requests_backups.py` files to be stored on the `visualization/keys/` folder. You can get the last from a template file on the AndroidRequestsBackups app, which will be downloaded during the installation, just make sure you copied the correct template. The others can be retrieved (a template) from the TranSapp app server [here](https://github.com/InspectorIncognito/server/tree/master/.travis).

### bower 

Bower manage javascript libraries used by visualization app but doesn't let you use it with sudo priviliges so it's probably you won't see a beatiful web page at the end of the process. To fix this problem you have to go `<path_to_project>` and run `bower install` with owner of directory where the project is.


## Running the installer

Go to the installation folder and execute the next command line.

**WARNING: PLEASE, do not call this script with like `./installScript.sh`**.

```bash
# run with sudo
$ sudo bash installScript.sh <SERVER_PUBLIC_IP> <DATABASE_NAME> <POSTGRES_USER> <POSTGRES_USER_PASS> <DUMP_DB_PATH> <MIGRATIONS>
```

When the script ends, you will need to append this machine IP address the `ALLOWED_HOSTS` django variable on the `settings.py` server file.

## Setting up apache

Finally, restart the apache server:
```bash
$ sudo service apache2 restart
```

## Create super user

To log in on web application on TranSapp visualization server you have to create a super user in django framework. You have to go `<path_to_project>` and run the next command ([createsuperuser](https://docs.djangoproject.com/en/1.10/ref/django-admin/#createsuperuser)).
```bash
$ python manage.py createsuperuser
```
With this new user you can create others through django admin web page (`<ip>/admin`). In the web app exists three types of users:
- TranSapp user
- Authority user
- Carrier user


====================================================
The Last bit of work
====================================================

You are almost ready on your journey. Just setup the jobs as described on the [AndroidRequestsBackups app](https://github.com/InspectorIncognito/AndroidRequestsBackups) .

