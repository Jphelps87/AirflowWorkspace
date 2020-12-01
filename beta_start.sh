#!/bin/bash

#this is a test to see if Docker does not suck. 

#Check if Airflow Dir is present in Domino Project....if not create airflow directory
if [ ! -d $DOMINO_WORKING_DIR/airflow ]; then
	echo "Creating Airflow Directory"
    mkdir -p  $DOMINO_WORKING_DIR/airflow/{dags,logs,postgresql}
    #build, link and modify postgres config files.
    echo "Move postgresql files into Domino Directory" 
	sudo chmod 777 -R /etc/postgresql/9.3/main/
	cp /etc/postgresql/9.3/main/postgresql.conf "$DOMINO_WORKING_DIR"/airflow/postgresql/
	cp /etc/postgresql/9.3/main/pg_hba.conf "$DOMINO_WORKING_DIR"/airflow/postgresql/
	#configure pg_hba.conf
	echo "Configure pg_hba.conf"
	sed -i '85s/peer/trust/' "$DOMINO_WORKING_DIR"/airflow/postgresql/pg_hba.conf
	sed -i '90s/peer/trust/' "$DOMINO_WORKING_DIR"/airflow/postgresql/pg_hba.conf
	sed -i '92s/md5/trust/' "$DOMINO_WORKING_DIR"/airflow/postgresql/pg_hba.conf
	#configue postgresql.conf file
	echo "Configure postgresql.conf"
	sed -i '59s/#listen_addresses/listen_addresses/' "$DOMINO_WORKING_DIR"/airflow/postgresql/postgresql.conf
	rm /etc/postgresql/9.3/main/postgresql.conf && ln -s $DOMINO_WORKING_DIR/airflow/postgresql/postgresql.conf /etc/postgresql/9.3/main/postgresql.conf
	rm /etc/postgresql/9.3/main/pg_hba.conf && ln -s $DOMINO_WORKING_DIR/airflow/postgresql/pg_hba.conf /etc/postgresql/9.3/main/pg_hba.conf	
	
	#build Airflow config file
	echo "Create Airflow.cfg"
	export AIRFLOW_HOME=/home/ubuntu/airflow && airflow initdb
	cp /home/ubuntu/airflow/airflow.cfg "$DOMINO_WORKING_DIR"/airflow/
	#configure and create symbolic link to new config file
	echo "Congire Airflow.cfg >>>>> Link File"
	sed -i '4s#/home/ubuntu/airflow/dags#$DOMINO_WORKING_DIR/airflow/dags' "$DOMINO_WORKING_DIR"/airflow/airflow.cfg
fi



# refactor environment vars
# echo "refactor environment variables"
# sudo sed -Ei "s#base_dir#$DOMINO_WORKING_DIR#g" /home/ubuntu/airflow/airflow.cfg

# #create DB in postgres
# sudo chown -R postgres /mnt/airflow/postgresql/
# sudo service postgresql start

# echo "CREATE USER airflow with PASSWORD 'airflow'" | sudo sh -c 'sudo -u postgres psql'
# echo "CREATE DATABASE airflow;" | sudo sh -c 'sudo -u postgres psql'
# echo "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO airflow;" | sudo sh -c 'sudo -u postgres psql'


# echo "build dependencies"
# airflow initdb
# airflow variables -s DOMINO_API_HOST $DOMINO_API_HOST
# airflow variables -s DOMINO_USER_API_KEY $DOMINO_USER_API_KEY
# #start airflow webserver and scheduler
# echo "Starting up Airflow"
# airflow webserver -p 8080 -hn "0.0.0.0" &
# airflow scheduler