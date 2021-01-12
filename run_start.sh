#!/bin/bash

curl https://raw.githubusercontent.com/Jphelps87/AirflowWorkspace/main/start.sh --output /home/ubuntu/airflowstart.sh
sudo chmod 777 /home/ubuntu/airflow/start.sh
sh ./home/ubuntu/airflow/start.sh

