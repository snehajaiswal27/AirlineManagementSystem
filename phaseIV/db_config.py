import mysql.connector
from dotenv import load_dotenv
import os

from datetime import datetime, timedelta
from flask import jsonify

# Load variables from .env
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '.env'))

def get_connection():
    return mysql.connector.connect(
        host=os.getenv("DB_HOST"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        database=os.getenv("DB_NAME")
    )