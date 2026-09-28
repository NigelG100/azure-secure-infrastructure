#!/bin/bash
set -e

# Require database password at runtime
if [ -z "$DB_PASSWORD" ]; then
  echo "ERROR: DB_PASSWORD environment variable is required."
  exit 1
fi

# Install application dependencies
apt-get update -y
apt-get install -y python3 python3-pip

pip3 install flask psycopg2-binary

# Create application directory
mkdir -p /opt/flaskapp

# Create Flask application
cat > /opt/flaskapp/app.py <<'PYTHON'
import os

from flask import Flask, jsonify
import psycopg2

app = Flask(__name__)

DB_HOST = "10.20.3.4"
DB_NAME = "portfolio"
DB_USER = "appuser"
DB_PASSWORD = os.environ.get("DB_PASSWORD")


@app.route("/")
def home():
    return jsonify(
        status="online",
        tier="application",
        message="Secure Azure Infrastructure"
    )


@app.route("/health")
def health():
    return jsonify(status="healthy")


@app.route("/api/database")
def database():
    try:
        connection = psycopg2.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            connect_timeout=5
        )

        cursor = connection.cursor()

        cursor.execute(
            """
            SELECT project_name, status
            FROM project_status
            ORDER BY id DESC
            LIMIT 1;
            """
        )

        result = cursor.fetchone()

        cursor.close()
        connection.close()

        if result is None:
            return jsonify(
                database="connected",
                status="No project data found"
            ), 200

        return jsonify(
            database="connected",
            project=result[0],
            status=result[1]
        )

    except Exception:
        return jsonify(
            database="connection_failed"
        ), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
PYTHON

# Store the database password in a root-readable environment file
install -m 600 /dev/null /etc/flaskapp.env
printf 'DB_PASSWORD=%s\n' "$DB_PASSWORD" > /etc/flaskapp.env

# Create systemd service
cat > /etc/systemd/system/flaskapp.service <<'SERVICE'
[Unit]
Description=Secure Azure Infrastructure Flask Application
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/flaskapp/app.py
EnvironmentFile=/etc/flaskapp.env
Restart=always
User=root

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable flaskapp
systemctl restart flaskapp

echo "Flask application configured successfully."