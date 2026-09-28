#!/bin/bash
set -e

# Install PostgreSQL
apt-get update -y
apt-get install -y postgresql postgresql-contrib

# Locate the installed PostgreSQL version
PG_VERSION=$(ls /etc/postgresql | head -n 1)
PG_CONF="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
PG_HBA="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"

# Allow PostgreSQL to listen on the VM's private network interface
sed -i "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"
sed -i "s/^listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"

# Allow PostgreSQL connections only from the application subnet
echo "host    portfolio    appuser    10.20.2.0/24    scram-sha-256" >> "$PG_HBA"

systemctl enable postgresql
systemctl restart postgresql


# Require database password to be supplied at runtime
if [ -z "$DB_PASSWORD" ]; then
  echo "ERROR: DB_PASSWORD environment variable is required."
  exit 1
fi

# Create application role if it does not already exist
sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='appuser'" | grep -q 1 || \
sudo -u postgres psql -c "CREATE ROLE appuser LOGIN PASSWORD '$DB_PASSWORD';"

# Create application database if it does not already exist
sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='portfolio'" | grep -q 1 || \
sudo -u postgres createdb -O appuser portfolio

# Initialize application table
sudo -u postgres psql -d portfolio <<'SQL'
CREATE TABLE IF NOT EXISTS project_status (
    id SERIAL PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL
);

INSERT INTO project_status (project_name, status)
SELECT 'Secure Azure Infrastructure', 'Operational'
WHERE NOT EXISTS (
    SELECT 1
    FROM project_status
    WHERE project_name = 'Secure Azure Infrastructure'
);

GRANT SELECT ON project_status TO appuser;
GRANT USAGE, SELECT ON SEQUENCE project_status_id_seq TO appuser;
SQL

systemctl restart postgresql

echo "PostgreSQL application database configured successfully."