from flask import Flask, jsonify
import psycopg2
import os

app = Flask(__name__)

# Configuration à partir des variables d'environnement
DB_HOST = os.getenv("DB_HOST", "db")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("POSTGRES_DB", "testdb")
DB_USER = os.getenv("POSTGRES_USER", "testuser")
DB_PASSWORD = os.getenv("POSTGRES_PASSWORD", "testpass")

def get_db_connection():
    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )
    return conn

@app.route("/health")
def health_check():
    return jsonify({"status": "ok"})

@app.route("/hello")
def hello():
    return jsonify({"message": "Hello, world!"})

@app.route("/dbtest")
def db_test():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT 1')
        result = cur.fetchone()
        cur.close()
        conn.close()
        if result:
            return jsonify({"db_connection": "successful"})
        else:
            return jsonify({"db_connection": "failed"}), 500
    except Exception as e:
        return jsonify({"db_connection": "failed", "error": str(e)}), 500

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
