FROM docker.io/dominodatalab/base:Ubuntu18_DAD_Py3.7_R3.6_20200508

#***********Set Domino Domain name************
#Example: demo.dominodatalab.com
ENV DOMAINNAME=demo.dominodatalab.com
RUN pip uninstall numpy -y
RUN pip install apache-airflow['postgres']==1.10.11 --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-1.10.11/constraints-3.6.txt"
RUN apt-key adv --recv-key --keyserver keyserver.ubuntu.com 51716619E084DAB9 && apt-get update && apt-get install postgresql postgresql-contrib -y
#download start script from github rebuild32
ADD https://raw.githubusercontent.com/Jphelps87/AirflowWorkspace/main/beta_start.sh /home/ubuntu/airflow/ 
RUN chmod 777 -R /home/ubuntu/airflow/
RUN pip install airflow-code-editor #allows in GUI editing of the dags
RUN pip install git+https://github.com/dominodatalab/python-domino.git #this is the domino python libary for airflow
