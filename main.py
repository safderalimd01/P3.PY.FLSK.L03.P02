from app import app
from flask import request, jsonify
import mysql.connector
from dotenv import load_dotenv
import json
from datetime import datetime, date
import decimal
import os
import mysql.connector
from datetime import datetime, date
from time import struct_time, mktime


config = {
    'user': os.environ.get('user'),
    'password': os.environ.get('password'),
    'host': os.environ.get('host'),
    'database': os.environ.get('database')
}

@app.route('/sales-dashboard')
def sales_dashboard():
	try:
		start_date = request.headers.get('start_date')
		end_date = request.headers.get('end_date')
		db = mysql.connector.connect(user = os.environ.get('user'),
									 password = os.environ.get('password'),
									 host = os.environ.get('host'),
									 database = os.environ.get('database'))
		if not isinstance(db, str):
			inputData = (start_date,end_date)
			outputData = ("oparam_kpi_invoice_count","oparam_kpi_client_count","oparam_kpi_total_sales_amount","oparam_err_flag","oparam_err_step", "oparam_err_msg")
			bindData = inputData + outputData
			cursor = db.cursor()
			cursor.callproc('sproc_sales_dashboard', bindData)

			ret = []
			for result in cursor.stored_results():
				res = result.fetchall()
				rowncols = [dict(zip(result.column_names, x)) for x in res]
				for row in rowncols:
					ret.append(row)
			close_connection(db, cursor)
     
			response = json.dumps(ret, cls = MyJSONEncoder)
			deserialized = json.loads(response)
			
			return jsonify({"sproc_result": deserialized}),200
		else:
			return api_failure(str(db))
	except Exception as error:
		return api_failure(str(error))

class MyJSONEncoder(json.JSONEncoder):
  
    def default(self, obj):
        if isinstance(obj, decimal.Decimal):
            return str(obj)
        if isinstance(obj, datetime):
            return obj.strftime('%Y-%m-%d %H:%M:%S')
        if isinstance(obj, date):
            return obj.strftime('%Y-%m-%d')
        return super(MyJSONEncoder, self).default(obj)

def api_failure(error):
    respone =  {
		"api_call_status": {
			"Message": error,
			"Status": "Failure"
		}
	}, 400
    return respone


def api_success(rowncols, argdict, message):
	respone = dict()
	if argdict and argdict.get("oparam_err_flag") == 1:
		respone["api_call_status"] = {
			"Message": argdict.get("oparam_err_msg"),
			"Status": "Failure"
		}
	else:
		respone["api_call_status"] = {
			"Message": message,
			"Status": "Success"
		}


	if argdict:
		respone["sproc_output_params"] = argdict
	if isinstance(rowncols, list):
		respone["sproc_output_result"] = rowncols
	return respone, 200

def close_connection(conn, cursor):
	cursor.close()
	conn.close()

if __name__ == "__main__":
	load_dotenv()
	app.run()
