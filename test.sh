#!/bin/bash

# curl https://raw.githubusercontent.com/Jphelps87/AirflowWorkspace/main/start.sh --output /home/ubuntu/airflowstart.sh
# sudo chmod 777 start.sh
# sh start.sh
workdir='/mnt'

editor_config='
[code_editor]
git_cmd = /usr/bin/git
git_default_args = -c color.ui=true
git_init_repo = True
root_directory = '"$workdir"'/airflow/dags
mount_name = data
mount_path = /home/ubuntu/airflow/data
mount1_name = logs
mount1_path = '"$workdir"'/airflow/logs'
	echo "$editor_config"