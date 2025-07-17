import dotenv from 'dotenv'
import Express from 'express'
import mysql from 'mysql2/promise'

dotenv.config()
const app = Express()

const WEB_PORT = process.env.WEB_PORT||8081;
app.listen(WEB_PORT,() => {
    console.info('[Server] Listening on :' + WEB_PORT)
})

const whitelist = process.env.CORS_WHITELIST ? process.env.CORS_WHITELIST.split(",") : [];

//TODO: record random player of the day
//TODO: Possibly split some information to a cache total

import RouteUser from './routes/user.js'
import RouteSessions from './routes/sessions.js'
import RouteCampaigns from './routes/campaigns.js'
import RouteMaps from './routes/maps.js'
import RouteTop from './routes/top.js'
import RouteMisc from './routes/misc.js'
import RouteValidation from './routes/validation.js'


(async function() {
    const details = {
        socketPath: process.env.MYSQL_SOCKET_PATH,
        host:     process.env.MYSQL_HOST   || 'localhost',
        port:     process.env.MYSQL_PORT   || 3306,
        database: process.env.MYSQL_DB     || 'left4dead2',
        user:     process.env.MYSQL_USER   || 'root',
        password: process.env.MYSQL_PASSWORD
    }
    console.log("details", details);

    const pool = mysql.createPool(details);
    console.log('Connecting to', (details.socketPath || `${details.host}:${details.port}`), 'database', details.database)

    // Middleware for parsing JSON requests
    app.use(Express.json({ limit: '10mb' }));

    app.use((req, res, next) => {
        if(!req.headers.origin || whitelist.includes(req.headers.origin)) {
            res.header("Access-Control-Allow-Origin", req.headers.origin ?? "*");
            res.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
            res.header("Access-Control-Allow-Headers", "Content-Type, Authorization");
        }
        next()
    })

    app.use('/api/user',        RouteUser(pool))
    app.use('/api/sessions',    RouteSessions(pool))
    app.use('/api/campaigns',   RouteCampaigns(pool))
    app.use('/api/maps',     RouteMaps(pool))
    app.use('/api/top',         RouteTop(pool))
    app.use('/api/validation',  RouteValidation)
    app.use('/api/',            RouteMisc(pool))

    app.get('*',(req,res) => {
        res.status(404).json({error:'PageNotFound'})
    })
    return pool;
})()