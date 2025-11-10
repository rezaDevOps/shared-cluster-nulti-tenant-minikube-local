const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    tenant_id: req.tenant.id,
    uptime: process.uptime()
  });
});

router.get('/ready', (req, res) => {
  // Add database connectivity check here
  res.status(200).json({
    status: 'ready',
    tenant_id: req.tenant.id
  });
});

module.exports = router;
