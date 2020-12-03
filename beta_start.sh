#!/bin/bash
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
	#dag dir 
	sed -i '4s#/home/ubuntu/airflow/dags#'"$DOMINO_WORKING_DIR"'/airflow/dags#' "$DOMINO_WORKING_DIR"/airflow/airflow.cfg
	#log dir
	sed -i '8s#/home/ubuntu/airflow/logs#'"$DOMINO_WORKING_DIR"'/airflow/logs#' "$DOMINO_WORKING_DIR"/airflow/airflow.cfg
	#proscess manager log
	sed -i '47s#/home/ubuntu/airflow/logs/dag_processor_manager/dag_processor_manager.log#'"$DOMINO_WORKING_DIR"'/airflow/logs/dag_processor_manager/dag_processor_manager.log#' "$DOMINO_WORKING_DIR"/airflow/airflow.cfg
	#Executor
	sed -i '69s#SequentialExecutor#LocalExecutor#' "$DOMINO_WORKING_DIR"/airflow/airflow.cfg
	#DB connecion 
	sed -i '74s#sqlite:////home/ubuntu/airflow/airflow.db#postgresql+psycopg2://airflow:airflow@localhost/airflow#' "$DOMINO_WORKING_DIR"/airflow/airflow.cfg
	#Load Examples
	sed -i '136s#True#False#' "$DOMINO_WORKING_DIR"/airflow/airflow.cfg
	#Load default connections
	sed -i '141s#True#False#' "$DOMINO_WORKING_DIR"/airflow/airflow.cfg
	#Expost Config file in UI
	sed -i '343s#False#True#' "$DOMINO_WORKING_DIR"/airflow/airflow.cfg
	#Catchup by default
	sed -i '639s#True#False#' "$DOMINO_WORKING_DIR"/airflow/airflow.cfg

	#Create Database and copy it to domino working dir. 
	#Create DB and user
	sudo chown -R postgres /mnt/airflow/postgresql/
	sudo service postgresql start
	echo "CREATE USER airflow with PASSWORD 'airflow'" | sudo sh -c 'sudo -u postgres psql'
	echo "CREATE DATABASE airflow;" | sudo sh -c 'sudo -u postgres psql'
	echo "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO airflow;" | sudo sh -c 'sudo -u postgres psql'
	#link new config file 
	rm /home/ubuntu/airflow/airflow.cfg && ln -s /mnt/airflow/airflow.cfg /home/ubuntu/airflow/airflow.c
	#build database and add env vars. 
	airflow initdb
	airflow variables -s DOMINO_API_HOST $DOMINO_API_HOST
	airflow variables -s DOMINO_USER_API_KEY $DOMINO_USER_API_KEY
	#backup airflow db
	sudo sh -c 'sudo -u postgres pg_dumpall --file=/mnt/airflow/postgresql/dumpall.sql'
fi

#create DB in postgres
sudo chown -R postgres /mnt/airflow/postgresql/
sudo service postgresql start

# echo "CREATE USER airflow with PASSWORD 'airflow'" | sudo sh -c 'sudo -u postgres psql'
# echo "CREATE DATABASE airflow;" | sudo sh -c 'sudo -u postgres psql'
# echo "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO airflow;" | sudo sh -c 'sudo -u postgres psql'
#echo "CREATE USER airflow with PASSWORD 'airflow'" | sudo sh -c 'sudo -u postgres psql'
#echo "CREATE DATABASE airflow;" | sudo sh -c 'sudo -u postgres psql'i
#echo "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO airflow;" | sudo sh -c 'sudo -u postgres psql'
echo "Restore Database"
sudo sh -c 'sudo -u postgres psql -f /mnt/airflow/postgresql/dumpall.sql'

echo "link custom airflow.cfg"
#Create symbolic link and remove default file
FILE=/home/ubutu/airflow/airflow.cfg
if [ -f /home/ubuntu/airflow/airflow.cfg ]; then
        echo "removeing old airflow.cfg file"
        rm  /home/ubuntu/airflow/airflow.cfg
fi
sudo ln -s $DOMINO_WORKING_DIR/airflow/airflow.cfg /home/ubuntu/airflow/airflow.cfg
# airflow initdb
# airflow variables -s DOMINO_API_HOST $DOMINO_API_HOST
# airflow variables -s DOMINO_USER_API_KEY $DOMINO_USER_API_KEY
#start airflow webserver and scheduler
echo "Starting up Airflow"
airflow webserver -p 8080 -hn "0.0.0.0" &
airflow scheduler