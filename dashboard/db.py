"""Read-only MySQL access used by the group's Streamlit dashboard."""
import os
from pathlib import Path

import pandas as pd
import pymysql
import streamlit as st
from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parent / '.env')


@st.cache_data(ttl=900, show_spinner=False)
def query(sql: str) -> pd.DataFrame:
    """Return results of one SELECT. Never write to the database here."""
    db = pymysql.connect(
        host=os.environ.get('MYSQL_HOST', '127.0.0.1'),
        port=int(os.environ.get('MYSQL_PORT', '3306')),
        user=os.environ.get('MYSQL_USER', 'root'),
        password=os.environ.get('MYSQL_PASSWORD', ''),
        database=os.environ.get('MYSQL_DATABASE', 'amazon_ecommerce'),
        charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor,
        connect_timeout=10,
        read_timeout=180,
        autocommit=True,
    )
    try:
        with db.cursor() as cursor:
            cursor.execute(sql)
            rows = cursor.fetchall()
        return pd.DataFrame(rows)
    finally:
        db.close()
