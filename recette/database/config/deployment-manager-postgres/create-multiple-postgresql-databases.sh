#!/bin/bash

set -e
set -u

function create_database() {
	local database=$1
	echo "  Grant database '$database' to user '$DB_SA_USERNAME' "
	psql -v ON_ERROR_STOP=1 --username postgres <<-EOSQL
	    CREATE DATABASE $database OWNER $DB_SA_USERNAME;
	    GRANT ALL PRIVILEGES ON DATABASE $database TO $DB_SA_USERNAME;
EOSQL
}

# Grant also acces to tables for liquibase
function grant_access_tables(){
	local database=$1
	echo "  Grant tables in '$database' to user '$DB_SA_USERNAME' "
	psql -v ON_ERROR_STOP=1 --username postgres -d $database <<-EOSQL
	GRANT ALL PRIVILEGES ON ALL TABLES in SCHEMA  public to $DB_SA_USERNAME;
EOSQL
}


function create_user(){
	echo "  Creating user '$DB_SA_USERNAME'"
	psql -v ON_ERROR_STOP=1 --username postgres <<-EOSQL
	    CREATE USER $DB_SA_USERNAME with PASSWORD '$DB_SA_PASSWORD';
EOSQL
	echo "User created"
}


function enable_ssl(){
	echo " Enabling SSL"
	psql -v ON_ERROR_STOP=1 --username postgres <<-EOSQL
		ALTER SYSTEM SET ssl_cert_file TO '/var/lib/postgresql/server.crt';
		ALTER SYSTEM SET ssl_key_file TO '/var/lib/postgresql/server.key';
		ALTER SYSTEM SET ssl TO 'on';
EOSQL
	echo "SSL is enabled"
}

# Create user
if [ -n "$DB_SA_USERNAME" ] && [ -n "$DB_SA_PASSWORD" ]; then
	create_user 

fi 

# Create DB
if [ -n "$POSTGRES_MULTIPLE_DATABASES" ]; then
	echo "Multiple database creation requested: $POSTGRES_MULTIPLE_DATABASES"
	for db in $(echo $POSTGRES_MULTIPLE_DATABASES | tr ',' ' '); do
		create_database $db
		grant_access_tables $db
	done
	echo "Multiple databases created"
fi

# Enable SSL
if [ -n "$ENABLE_SSL" ] && [ "$ENABLE_SSL" == "true" ]; then
	enable_ssl 
fi
