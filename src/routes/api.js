const express = require('express');
const router = express.Router();

router.get('/version', (req, res) => {
  res.json({
    version: '1.0.0',
    tenant_id: req.tenant.id,
    environment: process.env.NODE_ENV || 'development'
  });
});

router.get('/status', (req, res) => {
  res.json({
    status: 'running',
    tenant_id: req.tenant.id,
    memory_usage: process.memoryUsage(),
    uptime: process.uptime()
  });
});

module.exports = router;
