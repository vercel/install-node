const { join } = require('path');
const { parse } = require('url');
const { readFileSync } = require('fs');

const installScript = readFileSync(join(__dirname, 'install.sh'), 'utf8');

module.exports = async (req, res) => {
  res.setHeader('Content-Type', 'text/plain; charset=utf8');
  const { pathname } = parse(req.url);
  const version = pathname.substr(1);
  if (version) {
    return installScript.replace('VERSION=latest', `VERSION=${version}`);
  } else {
    return installScript;
  }
};
