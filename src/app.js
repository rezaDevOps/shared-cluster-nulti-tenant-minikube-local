const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
require('dotenv').config();

const healthRoutes = require('./routes/health');
const tenantRoutes = require('./routes/tenant');
const apiRoutes = require('./routes/api');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Tenant context middleware
app.use((req, res, next) => {
  req.tenant = {
    id: process.env.TENANT_ID || 'default',
    name: process.env.TENANT_NAME || 'Default Tenant'
  };
  next();
});

// Routes
app.use('/health', healthRoutes);
app.use('/tenant', tenantRoutes);
app.use('/api', apiRoutes);

// Root route
app.get('/', (req, res) => {
  res.json({
    message: `Welcome to ${req.tenant.name}`,
    tenant_id: req.tenant.id,
    version: process.env.npm_package_version || '1.0.0'
  });
});

app.listen(PORT, () => {
  console.log(`🚀 ${process.env.TENANT_NAME || 'SaaS App'} running on port ${PORT}`);
  console.log(`📊 Tenant ID: ${process.env.TENANT_ID || 'default'}`);
});
