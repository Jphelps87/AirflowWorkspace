FROM docker.io/dominodatalab/base:Ubuntu18_DAD_Py3.7_R3.6_20200508

#remove dependencies conflicts and install apache airflow
RUN pip uninstall numpy -y
RUN pip install apache-airflow['postgres']==1.10.11 --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-1.10.11/constraints-3.6.txt"

#install PostgreSQL before airflow initdb
RUN apt-key adv --recv-key --keyserver keyserver.ubuntu.com 51716619E084DAB9 && apt-get update && apt-get install postgresql postgresql-contrib -y
#link in custom config file for postgresql
RUN rm /etc/postgresql/10/main/postgresql.conf && ln -s /mnt/airflow/postgresql/V10/postgresql.conf /etc/postgresql/10/main/postgresql.conf
RUN rm /etc/postgresql/9.3/main/postgresql.conf && ln -s /mnt/airflow/postgresql/V93/postgresql.conf /etc/postgresql/9.3/main/postgresql.conf
RUN rm /etc/postgresql/10/main/pg_hba.conf && ln -s /mnt/airflow/postgresql/V10/pg_hba.conf /etc/postgresql/10/main/pg_hba.conf
RUN rm /etc/postgresql/9.3/main/pg_hba.conf && ln -s /mnt/airflow/postgresql/V93/pg_hba.conf /etc/postgresql/9.3/main/pg_hba.conf

#initdb gets run twice...this needs to run now so it can be refactored before the Postgres DB is ini.
RUN export AIRFLOW_HOME=/home/ubuntu/airflow && airflow initdb

#link custom config file from /mnt/airflow/airflow.cfg.
RUN rm /home/ubuntu/airflow/airflow.cfg && ln -s /mnt/airflow/airflow.cfg /home/ubuntu/airflow/airflow.cfg
RUN chmod 777 /home/ubuntu/airflow
#starts scheduler and webserver. Sets Domino Environment Vars and refactors envars in airflow.cfg
ADD https://gist.githubusercontent.com/Jphelps87/a4f4382c0d7464c87061916b06524982/raw/179cbf2a423165e2423877409ba48a46bef6c785/start_airflow_postgres.sh /home/ubuntu/airflow/
RUN chmod 777 -R /home/ubuntu/airflow/
#install plugins
RUN pip install airflow-code-editor #allows in GUI editing of the dags
RUN pip install git+https://github.com/dominodatalab/python-domino.git #this is the domino python libary for airflow