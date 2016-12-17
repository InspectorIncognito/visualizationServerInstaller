====================================================
Overview
====================================================

This repository mantains the code for deploying the TranSappVisualization server on a linux machine, which means:
- Step 1: linux user creation (defaults to `"visualization"`) and prompts for his password.
- Step 2: prerequisites installation
- Step 3: postgresql configuration
- Step 4: clone and setup of the django app
- Step 5: apache configuration


====================================================
PREREQUISITES
====================================================

## Linux Machine with Ubuntu 16.04

This has been tested on Ubuntu 16.04 machines.


## Superuser privileges

The installation script requires sudo access.


====================================================
Account Creation (TranSappViz)
====================================================

TODO: Create the "visualization" user account. Just make sure:

- this user does have a password
- a home: `/home/visualization`
- recursive permissions on its home: `sudo chown -R visualization:visualization /home/visualization`
- and also a `/home/visualization/.bashrc` file, to ease the ssh sessions. 

====================================================
Passwordless SSH Authentication (TranSapp)
====================================================

## Required Keys

To be able to install this server, you will require to have ssh access from the TranSapp server.

First, you need to generate keys for your root user:
```bash
# rsa encription, no passphrase, filename
$ ssh-keygen -t rsa -N "" -f "/root/.ssh/id_rsa"
```

Copy and paste the generated `.pub` key (`/root/.ssh/id_rsa.pub`) for root into the `/home/<user>/.ssh/authorized_keys`on the Visualization server, where `<user>` **relates to the user created while installing. SO you have two options, create the user account yourself or wait for the script to fail after the user generation process.**

Then, try to perform a ssh connection to the Visualization server, using the generated private key. Just accept when prompted whether to accept the fingerprint on this first connection.
```bash
sudo -u root ssh -i /root/.ssh/id_rsa <user>@<ip>
```

Note, you may need to install the `openssh-server` debian package on both machines.
```bash
$ sudo apt-get install openssh-server
```
====================================================
Prepare a Database Dump (TranSapp)
====================================================

## Database dump file

The installation process requires a complete database dump from the TranSapp server, only with the AndroidRequests models:

```bash
## ON TranSapp server
# perform dump
sudo -u postgres pg_dump <database_name> > dump.sql
# compress 
$ tar -zcvf dump.sql.tar.gz dump.sql
# send using the previous key
$ scp -i /root/.ssh/id_rsa  dump.sql.tar.gz <user>@<ip>:<destination_folder>

# perform backup and compresion of migrations  
tar -zcvf migrations.tar.gz <path_to_project>/AndroidRequests/migrations/*.py 
# send to TranSapp Visualization server
scp -i /root/.ssh/id_rsa migrations.tar.gz <>@<ip>:<destination_folder>

## ON TranSapp Visualization server
# uncompress
cd <destination_folder>
tar -zxvf dump.sql.tar.gz
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

The django app needs a secret key, you can [generate a new one](http://www.miniwebtool.com/django-secret-key-generator/) and manually replace the `<INSERT_DJANGO_SECRET_KEY>` script variable on `installScript.sh`.


## Understanding the installer

You need the following information:
- `<SERVER_PUBLIC_IP>`: This server public IP, used in apache configuration file
- `<DATABASE_NAME>`: name of the new database
- `<POSGRES_USER>`: name of the new postgres user
- `<POSTGRES_USER_PASS>`: postgres user's pasword
- `<DUMP_DB_PATH>`: full path to a DB dump (.sql file), obtained from the TranSapp App database


It is highly recommended to read the script before running it and ALSO EXECUTTE IT BY ONE PIECE AT A TIME!. Modify the configuration section on `installScript.sh` to select which steps do you want to run. The recommended way is to deactivate all steps and run them separately. 


## Known Problems

### Missing files when calling manage.py

The visualization server requires the `admins.json`, `email_config.json` and `android_requests_backups.py` files to be stored on the `visualization/keys/` folder. You can get the last from a template file on the AndroidRequestsBackups app, which will be downloaded during the installation, just make sure you copied the correct template. The others can be retrieved from the (TranSapp) server.


## Running the installer

Go to the installation folder and execute the next command line.

**WARNING: PLEASE, do not call this script with like `./installScript.sh`**.

```bash
# run with sudo
$ sudo bash installScript.sh <SERVER_PUBLIC_IP> <DATABASE_NAME> <POSTGRES_USER> <POSTGRES_USER_PASS> <DUMP_DB_PATH>
```

When the script ends, you will need to append this machine IP address the `ALLOWED_HOSTS` django variable on the `settings.py` server file.

## Setting up apache

Finally, restart the apache server:
```bash
$ sudo service apache2 restart
```


====================================================
The Last bit of work
====================================================

You are almost ready on your journey. Just setup the jobs as described on the [AndroidRequestsBackups app](https://github.com/InspectorIncognito/AndroidRequestsBackups) .

