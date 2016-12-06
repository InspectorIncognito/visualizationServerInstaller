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
DEPLOYMENT
====================================================

## Get the installer

```bash
# clone directly on the target machine
$ git clone https://github.com/InspectorIncognito/visualizationServerInstaller.git

# download anywhere and then copy the files to the visualization server:
# (e.g. if you want to bring up an AWS EC2 with ubuntu OS)
# through ssh:
$ scp -i <private_key> -r install <server-user>@<server-host>:/home/<server-user>
```

## Get Django key

The django app needs a secret key, you can [generate a new one](http://www.miniwebtool.com/django-secret-key-generator/) and manually replace the `<INSERT_DJANGO_SECRET_KEY>` script variable on `installScript.sh`.


## Run the installer

You need the following information:
- `<SERVER_PUBLIC_IP>`: used in apache configuration file
- `<DATABASE_NAME>`: name of the new database
- `<POSGRES_USER>`: name of the new postgres user
- `<POSTGRES_USER_PASS>`: postgres user's pasword
- `<DUMP_DB_PATH>`: full path to a DB dump SQL file, obtained from the TranSapp App database


It is highly recommended to read the script before running it and ALSO EXECUTTE IT BY ONE PIECE AT A TIME!. Modify the configuration section on `installScript.sh` to select which steps do you want to run. The recommended way is to deactivate all steps and run them separately. 


### RUN

```bash
# run with sudo
$ sudo su
$ bash installScript.sh <SERVER_PUBLIC_IP> <DATABASE_NAME> <POSTGRES_USER> <POSTGRES_USER_PASS> <DUMP_DB_PATH>
```

When the script ends, you will need to append this machine IP address the `ALLOWED_HOSTS` django variable on the `settings.py` file.

Finally, restart the apache server:
```bash
$ sudo service apache2 restart
```
