import { run } from 'micro';
import { join } from 'path';
import { parse } from 'url';
import { readFileSync } from 'fs';
import { IncomingMessage, ServerResponse } from 'http';

const installScript = readFileSync(join(__dirname, 'install.sh'), 'utf8');

function handler (req: IncomingMessage, res: ServerResponse): string {
  res.setHeader('Content-Type', 'text/plain; charset=utf8');
  const { pathname = '/' } = parse(req.url || '/');
  if (typeof pathname !== 'string') {
    throw new Error('No "pathname" provided!');
  }
  const version = pathname.substring(1);
  if (version) {
    return installScript.replace('VERSION=latest', `VERSION=${version}`);
  } else {
    return installScript;
  }
}

export default (req: IncomingMessage, res: ServerResponse) => run(req, res, handler);
