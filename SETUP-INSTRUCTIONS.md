# L4D2 Stats Plugin Setup Instructions

This guide will help you set up the L4D2 Stats Plugin to send data from your game server in a net cafe environment to your VPS server at l4d.test.com.

## 1. Game Server Setup (Net Cafe)

### Install the Plugin

1. Make sure SourceMod is installed on your L4D2 server
2. Copy the plugin files to your server:
   - Copy `l4d2_stats_recorder.smx` to `addons/sourcemod/plugins/`
   - Copy all include files to `addons/sourcemod/scripting/include/`

### Configure Database Connection

1. Create a `databases.cfg` file in `addons/sourcemod/configs/` with the following content:

```
"Databases"
{
    "driver_default"        "mysql"
    
    "stats"
    {
        "driver"            "mysql"
        "host"              "your_vps_server_ip"
        "database"          "left4dead2"
        "user"              "your_database_user"
        "pass"              "your_database_password"
        "port"              "3306"
    }
}
```

2. Replace:
   - `your_vps_server_ip` with your VPS server's IP address
   - `your_database_user` with your MySQL username
   - `your_database_password` with your MySQL password

### Network Configuration for Net Cafe

1. Make sure outbound connections to your VPS server on port 3306 are allowed
2. If your net cafe uses a firewall or proxy, configure it to allow connections to your VPS server

## 2. VPS Server Setup

### Prerequisites

- A VPS server with at least 2GB RAM
- Docker and Docker Compose installed
- Nginx installed
- Domain name (l4d.test.com) pointing to your VPS server

### Setup Steps

1. Copy the provided files to your VPS server:
   - `vps-docker-compose.yml`
   - `nginx-config.conf`
   - `vps-setup.sh`

2. Edit the files to replace placeholder values:
   - In `vps-docker-compose.yml`:
     - Replace `your_secure_root_password`, `your_database_user`, and `your_database_password`
   - In `nginx-config.conf`:
     - Replace `/path/to/your/certificate.crt` and `/path/to/your/private.key` with your SSL certificate paths

3. Make the setup script executable and run it:
   ```
   chmod +x vps-setup.sh
   ./vps-setup.sh
   ```

4. The script will:
   - Install necessary packages
   - Clone the repository
   - Set up Docker containers for MySQL, API, and UI
   - Configure Nginx
   - Set up SSL certificates

## 3. Testing the Setup

1. Start your L4D2 server with the plugin installed
2. Connect to your server and play a game
3. Check your VPS server's web interface at https://l4d.test.com to see if data is being recorded

## 4. Troubleshooting

### Game Server Issues

- Check the SourceMod error logs in `logs/errors_YYYY-MM-DD.log`
- Verify that the plugin is loaded with `sm plugins list` in the server console
- Test database connectivity with `sm_sql_test stats` in the server console

### VPS Server Issues

- Check Docker container logs with `docker logs l4d2stats-db`, `docker logs l4d2stats-api`, etc.
- Verify that the MySQL port is accessible from your game server with `telnet your_vps_server_ip 3306`
- Check Nginx logs in `/var/log/nginx/`

## 5. Security Considerations

- Consider using a more secure setup for production:
  - Don't expose MySQL directly to the internet; use a VPN or SSH tunnel
  - Use strong, unique passwords
  - Keep all software updated
  - Enable firewall rules to only allow necessary connections

## 6. Maintenance

- Regularly back up your MySQL database
- Monitor disk space usage
- Keep the system updated
