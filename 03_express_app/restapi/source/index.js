'use strict';

const express = require('express');

const PORT = process.env.PORT || 80;

const app = express();

// Static counter for the slow endpoint
let requestCount = 0;

app.get('/', function(req, res) {

    res.send('Express sier "Hello Learniken Fordypning!\n');

});

// 1. Liveness Probe: Tells Kubernetes if the app is alive.
// Keep this extremely lightweight. Do not check heavy dependencies here.
app.get('/healthz', (req, res) => {
    const delay = requestCount * 100;
    
    setTimeout(() => {        
        res.status(200).json({ 
          status: 'UP', 
          timestamp: new Date(), 
          Requestcount: requestCount,
          Delay: delay,
        });
    }, delay);
  
});

// 2. Readiness Probe: Tells Kubernetes if the app can accept traffic.
// Fail this immediately if the app is shutting down.
app.get('/readyz', async (req, res) => {
    res.status(200).json({ status: 'UP' });  
});


app.get('/slow', function(req, res) {
    const n = parseInt(req.query.n) || 100;
    requestCount++;
    const delay = requestCount * n;
    res.send(`Request #${requestCount}, delayed by ${delay}ms\n`);
});

app.listen(PORT);

console.log('Running on http://localhost:' + PORT);