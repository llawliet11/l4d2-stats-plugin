# L4D2 Stats Plugin Docker Setup

This guide explains how to set up the L4D2 Stats Plugin backend using Docker Compose.

## Prerequisites

- Docker and Docker Compose installed on your VPS server
- The L4D2 Stats Plugin repository cloned to your server

## Configuration Files

### 1. .env

The `.env` file contains environment variables used by Docker Compose. This keeps sensitive information like passwords out of your docker-compose.yaml file.

Default content:
```
# Database Configuration
MARIADB_ROOT_PASSWORD=rootpassword
MARIADB_DATABASE=left4dead2
MARIADB_USER=l4d2user
MARIADB_PASSWORD=l4d2password

# API Configuration
API_PORT=8081
UI_PORT=8080

# Database Connection for API
MYSQL_HOST=mariadb
MYSQL_DB=left4dead2
MYSQL_USER=l4d2user
MYSQL_PASSWORD=l4d2password
```

**Important**: You should change the default passwords in this file before deploying to production.

### 2. docker-compose.yaml

The `docker-compose.yaml` file has been configured to:

- Run a MariaDB 10.7 database server (required for UUID data type support)
- Import the `stats_database.sql` schema on first startup
- Run the API server that connects to the database
- Run the UI server that provides the web interface
- Run phpMyAdmin for database management
- Use environment variables from the `.env` file

### 3. databases.cfg (for your L4D2 server)

Create a `databases.cfg` file in your L4D2 server's `addons/sourcemod/configs/` directory with the following content:

```
"Databases"
{
    "driver_default"        "mysql"

    "stats"
    {
        "driver"            "mysql"
        "host"              "YOUR_VPS_IP_ADDRESS"
        "database"          "left4dead2"
        "user"              "l4d2user"
        "pass"              "l4d2password"
        "port"              "3306"
    }
}
```

Replace:
- `YOUR_VPS_IP_ADDRESS` with the public IP address of your VPS server
- `l4d2user` and `l4d2password` with the values you set in your `.env` file (MARIADB_USER and MARIADB_PASSWORD)

## Setup Instructions

1. **Start the Docker containers**:

   ```bash
   docker-compose up -d
   ```

   This will:
   - Create a MariaDB container
   - Import the database schema
   - Start the API and UI servers

2. **Verify the services are running**:

   ```bash
   docker-compose ps
   ```

   You should see all four services (mariadb, l4d2stats-api, l4d2stats-ui, l4d2stats-phpmyadmin) running.

3. **Check the logs for any errors**:

   ```bash
   docker-compose logs
   ```

   Or check a specific service:

   ```bash
   docker-compose logs mariadb
   docker-compose logs l4d2stats-api
   docker-compose logs l4d2stats-ui
   docker-compose logs l4d2stats-phpmyadmin
   ```

4. **Access the web interface**:

   Open a web browser and navigate to:

   ```
   http://YOUR_VPS_IP_ADDRESS:8080
   ```

4. **Access phpMyAdmin**:

   Open a web browser and navigate to:

   ```
   http://YOUR_VPS_IP_ADDRESS:8082
   ```

   You can log in with either:
   - Username: `root` and password: `MARIADB_ROOT_PASSWORD` from your .env file
   - Username: `l4d2user` (or your MARIADB_USER) and password: `MARIADB_PASSWORD` from your .env file

## Network Configuration

- The MariaDB database is exposed on port 3306
- The API server is exposed on port 8081
- The UI server is exposed on port 8080
- phpMyAdmin is exposed on port 8082

Make sure your firewall allows incoming connections to these ports.

## Security Considerations

The default configuration uses simple passwords for demonstration purposes. For a production environment, you should:

1. Change the database passwords in `docker-compose.yaml`:
   - `MARIADB_ROOT_PASSWORD`
   - `MARIADB_PASSWORD`

2. Update the corresponding password in the API service environment variables:
   - `MYSQL_PASSWORD`

3. Update the password in your L4D2 server's `databases.cfg` file.

4. Consider using a reverse proxy (like Nginx) with SSL to secure the web interface.

5. Restrict access to the database port (3306) to only allow connections from your L4D2 server.

## Troubleshooting

### Database Connection Issues

If your L4D2 server cannot connect to the database:

1. Verify the database container is running:
   ```bash
   docker-compose ps mariadb
   ```

2. Check if the database port is accessible from your L4D2 server:
   ```bash
   telnet YOUR_VPS_IP_ADDRESS 3306
   ```

3. Check the MariaDB logs for any errors:
   ```bash
   docker-compose logs mariadb
   ```

4. Verify your VPS firewall allows incoming connections on port 3306.

### API Server Issues

If the API server is not working:

1. Check the API server logs:
   ```bash
   docker-compose logs l4d2stats-api
   ```

2. Verify the API server can connect to the database.

### UI Server Issues

If the web interface is not loading:

1. Check the UI server logs:
   ```bash
   docker-compose logs l4d2stats-ui
   ```

2. Verify the UI server can connect to the API server.

## Backup and Restore

### Backing Up the Database

```bash
docker-compose exec mariadb sh -c 'exec mysqldump -uroot -p"$MARIADB_ROOT_PASSWORD" left4dead2' > backup.sql
```

### Restoring the Database

```bash
cat backup.sql | docker-compose exec -T mariadb sh -c 'exec mysql -uroot -p"$MARIADB_ROOT_PASSWORD" left4dead2'
```

### Credits
* [Jackzmc](https://github.com/Jackzmc) - Plugin and API