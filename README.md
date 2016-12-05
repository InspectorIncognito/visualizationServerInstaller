====================================================
Considerations
====================================================

This repository mantains the code for deploying the TranSappVisualization server on a linux machine, which means:

- Step 1: It creates the linux user `"$USER_NAME"` (defaults to `"visualization"`) and prompts for his password.
- Step 2: Installs server prerequisites: 
- Step 3: It configures postgresql
- Step 4: Clone and setup of the django app
- Step 5: It configures apache


====================================================
PREREQUISITES
====================================================

## Linux Machine with Ubuntu 14.04

This has been tested on Ubuntu 16.04 machines.

## Superuser privileges

The installation script requires sudo privileges.


====================================================
DEPLOYMENT
====================================================

## Get the installer

```(bash)
# Run on the target machine
$ git clone https://github.com/InspectorIncognito/serverInstaller.git

# or download anywhere and then copy the files to the server:
# (e.g. if you want to bring up an AWS EC2 with ubuntu OS)
# through ssh:
$ scp -i key -r install ubuntu@<ip>:/home/ubuntu
```
##Get Django key

The django app need a secret key, for that you need get a new key (http://www.miniwebtool.com/django-secret-key-generator/) and reeplaze it
<INSERT_DJANGO_SECRET_KEY> in the installScript.sh


## Run the installer

You need the following information:
- `<SERVER_PUBLIC_IP>`: used in apache configuration file
- `<DATABASE_NAME>`: name of the new database
- `<POSGRES_USER>`: name of the new postgres user
- `<POSTGRES_USER_PASS>`: pasword of the postgres user 
- `<DUMP_DB_PATH>`: a dump of the transapp database


It is highly recommended to read the script before running it and ALSO EXECUTTE IT BY ONE PIECE AT A TIME!. Modify the configuration section on `installScript.sh` to select which steps do you want to run. The recommended way is to deactivate all steps and run then separately. 

### RUN

```(bash)
# run with sudo
$ sudo su
$ bash installScript.sh <SERVER_PUBLIC_IP> <DATABASE_NAME> <POSTGRES_USER> <POSTGRES_USER_PASS> <DUMP_DB_PATH>
```

FInally, after ends the script you need add the ip direction to the django setting (in ALLOWED_HOSTS) and restart the apache server.

```(bash)
$ sudo service apache2 restart
```
