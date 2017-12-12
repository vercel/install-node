const { join } = require('path');
const { readFileSync } = require('fs');

const installScript = readFileSync(join(__dirname, 'install.sh'), 'utf8');

module.exports = async (req, res) => {
  res.setHeader('Content-Type', 'text/x-shellscript');
  return installScript;
};
