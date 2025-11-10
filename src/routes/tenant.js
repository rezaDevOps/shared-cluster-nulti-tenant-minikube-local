const express = require('express');
const router = express.Router();

router.get('/info', (req, res) => {
  res.json({
    tenant_id: req.tenant.id,
    tenant_name: req.tenant.name,
    timestamp: new Date().toISOString()
  });
});

router.get('/data', (req, res) => {
  // Simulate tenant-specific data
  const tenantData = {
    tenant_id: req.tenant.id,
    data: [
      { id: 1, name: `Item 1 for ${req.tenant.name}`, created_at: new Date().toISOString() },
      { id: 2, name: `Item 2 for ${req.tenant.name}`, created_at: new Date().toISOString() },
      { id: 3, name: `Item 3 for ${req.tenant.name}`, created_at: new Date().toISOString() }
    ]
  };
  
  res.json(tenantData);
});

module.exports = router;
