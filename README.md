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


## Database dump file

The installation process requires a database dump from the TranSapp server, only with the AndroidRequests models:

```bash
## ON TranSapp server
# perform dump
sudo -u postgres pg_dump <database_name> --table='*ndroid*equests_*' > dump.sql

# compress 
$ tar -zcvf dump.sql.tar.gz dump.sql

## ON TranSapp Visualization server
# send using the previous key
$ scp dump.tar.gz <user>@<ip>:destination_folder

# uncompress
cd <path>
tar -zxvf dump.tar.gz
```


====================================================
DEPLOYMENT
====================================================

## Get the installer

```bash
# clone directly on the target machine
$ git clone https://github.com/InspectorIncognito/visualizationServerInstaller.git

# or download anywhere and then copy the files to the visualization server:
# e.g. if you want to bring up an AWS EC2 with ubuntu OS:
$ scp -i <private_key> -r install <server-user>@<server-host>:/home/<server-user>
```

## Get Django key

The django app needs a secret key, you can [generate a new one](http://www.miniwebtool.com/django-secret-key-generator/) and manually replace the `<INSERT_DJANGO_SECRET_KEY>` script variable on `installScript.sh`.


## Run the installer

You need the following information:
- `<SERVER_PUBLIC_IP>`: This server public IP, used in apache configuration file
- `<DATABASE_NAME>`: name of the new database
- `<POSGRES_USER>`: name of the new postgres user
- `<POSTGRES_USER_PASS>`: postgres user's pasword
- `<DUMP_DB_PATH>`: full path to a DB dump (.sql file), obtained from the TranSapp App database


It is highly recommended to read the script before running it and ALSO EXECUTTE IT BY ONE PIECE AT A TIME!. Modify the configuration section on `installScript.sh` to select which steps do you want to run. The recommended way is to deactivate all steps and run them separately. 


### RUN

Go to the installation folder and execute the next command line.

```bash
# run with sudo
$ sudo bash installScript.sh <SERVER_PUBLIC_IP> <DATABASE_NAME> <POSTGRES_USER> <POSTGRES_USER_PASS> <DUMP_DB_PATH>
```

When the script ends, you will need to append this machine IP address the `ALLOWED_HOSTS` django variable on the `settings.py` file.

Finally, restart the apache server:
```bash
$ sudo service apache2 restart
```


Then, setup the jobs as described on the [AndroidRequestsBackups app](https://github.com/InspectorIncognito/AndroidRequestsBackups) .

