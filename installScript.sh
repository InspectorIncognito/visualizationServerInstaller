#! /bin/bash

#####################################################################
# COMMAND LINE INPUT
#####################################################################
if [ -z "$1" ]; then
    echo "It was not specified server ip"
    exit 1 
fi
if [ -z "$2" ]; then
    echo "It was not specified database name"
    exit 1
fi
if [ -z "$3" ]; then
    echo "It was not specified postgres user name"
    exit 1
fi
if [ -z "$4" ]; then
    echo "It was not specified postgres user password"
    exit 1
fi
if [ -z "$5" ]; then
    echo "It was not specified database dump path"
    exit 1
fi
if [ -z "$6" ]; then
    echo "It was not specified tar file of TranSapp app server migrations"
    exit 1
fi
if [ -z "$7" ]; then
    echo "It was not specified linux user name"
    exit 1
fi

IP_SERVER=$1
DATABASE_NAME=$2
POSTGRES_USER=$3
POSTGRES_PASS=$4
DUMP=$5
MIGRATION=$6
LINUX_USER_NAME=$7

#####################################################################
# SETUP
#####################################################################

SCRIPT="$(readlink "$0")"
INSTALLER_FOLDER="$(dirname "$SCRIPT")"
if [ ! -d "$INSTALLER_FOLDER" ]; then
  echo "failed to retrieve the installer folder path"
  exit 1
fi
cd "$INSTALLER_FOLDER"

COLOR_RED='\033[0;31m'
COLOR_NC='\033[0m'


#####################################################################
# CONFIGURATION
#####################################################################

clone_project=false
install_packages=false
postgresql_configuration=false
project_configuration=false
apache_configuration=false

PROJECT_DEST=/home/"$LINUX_USER_NAME"/Documents


#####################################################################
# USER CONFIGURATION
#####################################################################

# stores the current path
if id "$LINUX_USER_NAME" >/dev/null 2>&1; then
    echo "User $LINUX_USER_NAME already exists.. skipping"
else
    echo "User $LINUX_USER_NAME does not exists.. CREATING!"
    adduser "$LINUX_USER_NAME"
fi

#####################################################################
# CLONE PROJECT
#####################################################################

if $clone_project; then
  sudo apt-get --yes install git
  echo ""
  echo --
  echo "Server directory: "
  echo --
  echo ""

  # create project destination path
  sudo -u "$LINUX_USER_NAME" mkdir -p "$PROJECT_DEST"
  cd "$PROJECT_DEST"

  # clone project from git
  echo ""
  echo "----"
  echo "Clone project from gitHub"
  echo "----"
  echo ""

  DO_CLONE=true
  if [ -d visualization ]; then
    echo ""
    echo "The InspectorIncognito/visualization.git repository already exists."
    read -p "Do you want to remove it and clone it again? [Y/n]: " -n 1 -r
    echo # (optional) move to a new line
    DO_CLONE=false
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      echo "Removing repository 'visualization' at: $(pwd)/visualization"
      rm -rf visualization
      DO_CLONE=true
    fi
  fi

  if [ "$DO_CLONE" = "true" ]; then
    git clone https://github.com/InspectorIncognito/visualization.git
    cd visualization
    git submodule init
    git submodule update
    chown -R "$LINUX_USER_NAME":"$LINUX_USER_NAME" "$PROJECT_DEST"
  fi

fi

#####################################################################
# REQUIREMENTS
#####################################################################

if $install_packages; then
    PREREQUISITES_SCRIPT="$PROJECT_DEST"/visualization/prerequisites.sh
    if [ -e "$PREREQUISITES_SCRIPT" ]; then
      bash "$PREREQUISITES_SCRIPT"
    else
      printf "I ${COLOR_RED}Prerequisites Installer script not found: $PREREQUISITES_SCRIPT${COLOR_NC}\n"
    fi
fi

#####################################################################
# POSTGRESQL
#####################################################################
if $postgresql_configuration; then
  echo ----
  echo ----
  echo "Postgresql"
  echo ----
  echo ----

  CREATE_DATABASE=true
  DATABASE_EXISTS=$(sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DATABASE_NAME")
  if [ "$DATABASE_EXISTS" ]; then
      echo ""
      echo "The database $DATABASE_NAME already exists."
      read -p "Do you want to remove it and create it again? [Y/n]: " -n 1 -r
      echo # (optional) move to a new line
      CREATE_DATABASE=false
      if [[ $REPLY =~ ^[Yy]$ ]]
      then
        echo "Removing database $DATABASE_NAME..."
        sudo -u postgres psql -c "DROP DATABASE $DATABASE_NAME;"
        CREATE_DATABASE=true
      fi
  fi
  
  if [ "$CREATE_DATABASE" ]; then
      # get the version of psql
      psqlVersion=$(psql -V | egrep -o '[0-9]{1,}\.[0-9]{1,}')
      # change config of psql
      cd "$INSTALLER_FOLDER"
      python replaceConfigPSQL.py "$psqlVersion"
      service postgresql restart
  
      # create user and database
      postgres_template_file="$INSTALLER_FOLDER"/template_postgresqlConfig.sql
      postgres_final_file="$INSTALLER_FOLDER"/postgresqlConfig.sql
      # copy the template
      cp "$postgres_template_file" "$postgres_final_file"
      # change parameters
      sed -i -e 's/<DATABASE>/'"$DATABASE_NAME"'/g' "$postgres_final_file"
      sed -i -e 's/<USER>/'"$POSTGRES_USER"'/g' "$postgres_final_file"
      sed -i -e 's/<PASSWORD>/'"$POSTGRES_PASS"'/g' "$postgres_final_file"
  
      # postgres user has to be owner of the file and folder that contain the file
      #current_owner=$(stat -c '%U' .)
      # change owner to let postgres user exec file
      chown postgres "$INSTALLER_FOLDER"/postgresqlConfig.sql
      chown postgres "$INSTALLER_FOLDER"
      sudo -u postgres psql -f "$postgres_final_file"
      rm "$postgres_final_file"
      #sudo chown "${current_owner}" "$postgres_final_file"
      #sudo chown "${current_owner}" "$INSTALLER_FOLDER"
  
      # replace the owner by the database user defined here and after load dump
      sed -i -e 's/TO [a-zA-Z0-9]\+\;/TO '"$POSTGRES_USER"';/g' "$DUMP" 
      sudo -u postgres psql "$DATABASE_NAME" < "$DUMP"
  fi

  echo ----
  echo ----
  echo "Postgresql ready"
  echo ----
  echo ----
fi


#####################################################################
# SETUP DJANGO APP
#####################################################################
if $project_configuration; then
  echo ----
  echo ----
  echo "Project configuration"
  echo ----
  echo ----

  # configure wsgi
  cd "$INSTALLER_FOLDER"
  python wsgiConfig.py "$PROJECT_DEST"

  # create secret_key.txt file
  mkdir -p "$PROJECT_DEST"/visualization/visualization/keys
  SECRET_KEY_FILE="$PROJECT_DEST"/visualization/visualization/keys/secret_key.txt
  touch "$SECRET_KEY_FILE"
  echo "<INSERT_DJANGO_SECRET_KEY>" > "$SECRET_KEY_FILE"
 
  database_template_file="$INSTALLER_FOLDER"/template_database.py
  database_final_file="$PROJECT_DEST"/visualization/visualization/keys/database.py

  # copy the template

  cp "$database_template_file" "$database_final_file"
  sed -i -e 's/<DATABASE>/'"$DATABASE_NAME"'/g' "$database_final_file"
  sed -i -e 's/<USER>/'"$POSTGRES_USER"'/g' "$database_final_file"
  sed -i -e 's/<PASSWORD>/'"$POSTGRES_PASS"'/g' "$database_final_file"

  # create folder used by loggers if not exist
  LOG_DIR="$PROJECT_DEST"/visualization/visualization/logs
  mkdir -p "$LOG_DIR"
  touch "$LOG_DIR"/file.log
  chmod 777 "$LOG_DIR"/file.log


  # install all dependencies of python to the project
  echo "--------------------------------------------------------------------------------"

  # detect last migration executed in AndroidRequests app
  QUERY="select name from django_migrations where app='AndroidRequests' ORDER BY applied DESC limit 1;"
  LAST_MIGRATION=$(sudo -u postgres -i psql -d "$DATABASE_NAME" -c "$QUERY"| sed '3q;d')
  
  # move TranSapp app server migrations to TranSapp visualization server migration folder
  tar -zxvf "$MIGRATION" -C "$PROJECT_DEST"/visualization/AndroidRequests/migrations 
  # fixed migration dependencies
  sed -i -e "s/CHANGE_ME/'$LAST_MIGRATION'/g" "$PROJECT_DEST"/visualization/AndroidRequests/migrations/0011_auto_20161025_1616.py

  # uptade the model of the database
  python "$PROJECT_DEST"/visualization/manage.py migrate
  python "$PROJECT_DEST"/visualization/manage.py collectstatic

  # add the cron task data
  #python manage.py crontab add

  echo ----
  echo ----
  echo "Project configuration ready"
  echo ----
  echo ----
fi


#####################################################################
# APACHE CONFIGURATION
#####################################################################

if $apache_configuration; then
  echo ----
  echo ----
  echo "Apache configuration"
  echo ----
  echo ----
  # configure apache 2.4

  cd "$INSTALLER_FOLDER"
  configApache="transapp_visualization.conf"

  sudo python configApache.py "$PROJECT_DEST" "$IP_SERVER" "$configApache" visualization
  sudo a2dissite 000-default.conf
  sudo a2ensite "$configApache"
  # ssl configuration
  sudo cp ssl.conf /etc/apache2/mods-available
  sudo a2enmod ssl
  sudo a2enmod headers 

  # create the certificfate
  # this part must be by hand
  sudo mkdir /etc/apache2/ssl
  cd /etc/apache2/ssl

  sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/apache2/ssl/apache.key -out /etc/apache2/ssl/apache.crt


  sudo service apache2 reload

  # change the MPM of apache.
  # MPM is the way apache handles the request
  # using proceses, threads or a bit of both.

  # this is the default 
  # is though to work whith php
  # becuase php isn't thread safe.
  # django works better whith
  # MPM worker, but set up
  # the number of precess and
  # threads whith care.

  sudo a2dismod mpm_event 
  sudo a2enmod mpm_worker 

  # configuration for the worker
  # mpm.
  # apacheSetup arg1 arg2 arg3 ... arg7
  # arg1 StartServers: initial number of server processes to start
  # arg2 MinSpareThreads: minimum number of 
  #      worker threads which are kept spare
  # arg3 MaxSpareThreads: maximum number of
  #      worker threads which are kept spare
  # arg4 ThreadLimit: ThreadsPerChild can be 
  #      changed to this maximum value during a
  #      graceful restart. ThreadLimit can only 
  #      be changed by stopping and starting Apache.
  # arg5 ThreadsPerChild: constant number of worker 
  #      threads in each server process
  # arg6 MaxRequestWorkers: maximum number of threads
  # arg7 MaxConnectionsPerChild: maximum number of 
  #      requests a server process serves
  cd "$INSTALLER_FOLDER"
  sudo python apacheSetup.py 1 10 50 30 25 75

  sudo service apache2 restart

  # this lets apache add new things to the media folder
  # to store the pictures of the free report
  sudo adduser www-data "$USER_NAME"

  echo ----
  echo ----
  echo "Apache configuration ready"
  echo ----
  echo ----
fi

cd "$INSTALLER_FOLDER"

echo "Installation ready."
echo "To check that its all ok, enter to 0.0.0.0"

