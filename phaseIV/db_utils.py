from flask import jsonify
from db_config import get_connection
from datetime import datetime, timedelta

# Grabs data from database and returns it formatted in JSON
def query_view(view_name):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(f"SELECT * FROM {view_name}")
        columns = [desc[0] for desc in cursor.description]
        rows = cursor.fetchall()

        serialized = []
        for row in rows:
            row_dict = {
                col: str(val) if isinstance(val, (timedelta, datetime)) else val
                for col, val in zip(columns, row)
            }
            serialized.append(row_dict)
    except Exception as e:
        return f"<h2>Error in view '{view_name}':</h2><pre>{e}</pre>"
    finally:
        conn.close()

    return jsonify(serialized)


# This is for calling procedures
def call_procedure(proc_name, args):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.callproc(proc_name, args)
        conn.commit()
    finally:
        conn.close()