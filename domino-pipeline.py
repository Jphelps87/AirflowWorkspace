from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.python_operator import PythonOperator
from domino import Domino
from airflow.models import Variable
# Initialize Domino API object with the api_key and host
api_key=Variable.get("DOMINO_USER_API_KEY")
host=Variable.get("DOMINO_API_HOST")
domino = Domino("jphelps/airflow-pipeline",api_key,host)
# Parameters to DAG object
default_args = {
    'owner': 'domino',
    'depends_on_past': False,
    'start_date': datetime(2020, 11, 9),
    'retries': 1,
    'retry_delay': timedelta(minutes=.5),
    'end_date': datetime(2022, 7, 10),
}
# Instantiate a DAG
dag = DAG('domino_pipeline', description='Execute Airflow DAG in Domino',default_args=default_args,schedule_interval=timedelta(days=1), catchup=False)
# Define Task instances in Airflow to kick off Jobs in Domino
t1 = PythonOperator(task_id='get_dataset_1', python_callable=domino.runs_start_blocking, dag=dag, op_kwargs={"command":["src/data/get_dataset_1.py"]})
t2= PythonOperator(task_id='get_dataset_2', python_callable=domino.runs_start_blocking, op_kwargs={"command":["src/data/get_dataset_2.py"]}, dag=dag)
t3 = PythonOperator(task_id='get_dataset_3', python_callable=domino.runs_start_blocking, op_kwargs={"command":["src/models/get_dataset_3.sh"]}, dag=dag)
t4 = PythonOperator(task_id='clean_data', python_callable=domino.runs_start_blocking, op_kwargs={"command":["src/data/cleaning_data.py"]}, dag=dag)
t5 = PythonOperator(task_id='generate_features_1', python_callable=domino.runs_start_blocking, op_kwargs={"command":["src/features/word2vec_features.py"]}, dag=dag)
t6 = PythonOperator(task_id='run_model_1', python_callable=domino.runs_start_blocking, op_kwargs={"command":["src/models/run_model_1.py"]}, dag=dag)
t7 = PythonOperator(task_id='do_feature_engg', python_callable=domino.runs_start_blocking, op_kwargs={"command":["src/features/feature_eng.py"]}, dag=dag)
t8 = PythonOperator(task_id='run_model_2', python_callable=domino.runs_start_blocking, op_kwargs={"command":["src/models/run_model_2.py"]}, dag=dag)
t9 = PythonOperator(task_id='run_model_3', python_callable=domino.runs_start_blocking, op_kwargs={"command":["src/models/run_model_3.py"]}, dag=dag)
t10 = PythonOperator(task_id='run_final_report', python_callable=domino.runs_start_blocking, op_kwargs={"command":["src/report/report.sh"]}, dag=dag)
# Define your dependencies
t2.set_upstream(t1)
t3.set_upstream(t1)
t4.set_upstream(t2)
t5.set_upstream(t3)
t6.set_upstream([t4, t5])
t7.set_upstream(t4)
t8.set_upstream(t7)
t9.set_upstream(t7)
t10.set_upstream([t6, t8, t9])