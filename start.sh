#!/bin/bash

#Check if Airflow Dir is present in Domino
if [ ! -d $DOMINO_WORKING_DIR/airflow ]; then
    cd /tmp
    git clone https://github.com/imarchenko/domino_airflow_starter_kit.git
    cd domino_airflow_starter_kit
    find . -name "*git*" | xargs -I {} rm -rf {}
    mv airflow $DOMINO_WORKING_DIR/airflow
fi

#refactor environment vars
echo "refactor environment variables"
sudo sed -Ei "s#base_dir#$DOMINO_WORKING_DIR#g" /home/ubuntu/airflow/airflow.cfg

#create DB in postgres
sudo chown -R postgres /mnt/airflow/postgresql/
sudo service postgresql start

echo "CREATE USER airflow with PASSWORD 'airflow'" | sudo sh -c 'sudo -u postgres psql'
echo "CREATE DATABASE airflow;" | sudo sh -c 'sudo -u postgres psql'
echo "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO airflow;" | sudo sh -c 'sudo -u postgres psql'


echo "build dependencies"

airflow variables -s DOMINO_API_HOST $DOMINO_API_HOST
airflow variables -s DOMINO_USER_API_KEY $DOMINO_USER_API_KEY
airflow initdb
#start airflow webserver and scheduler
echo "Starting up Airflow"
airflow webserver -p 8080 -hn "0.0.0.0" &
airflow scheduler