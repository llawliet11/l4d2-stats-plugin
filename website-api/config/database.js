import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

dotenv.config();

/**
 * Database configuration and connection pool
 * This file exports a MySQL connection pool for use across the application
 */

const details = {
    socketPath: process.env.MYSQL_SOCKET_PATH,
    host:     process.env.MYSQL_HOST   || 'localhost',
    port:     process.env.MYSQL_PORT   || 3306,
    database: process.env.MYSQL_DB     || 'left4dead2',
    user:     process.env.MYSQL_USER   || 'root',
    password: process.env.MYSQL_PASSWORD
};

// Create and export the connection pool
const pool = mysql.createPool(details);

console.log('Database pool created for', (details.socketPath || `${details.host}:${details.port}`), 'database', details.database);

export default pool;
