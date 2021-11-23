# install-node.vercel.app

Simple one-liner shell script that installs Node.js binaries.

<img src="./demo/install-node.svg" width="640" alt="Demo" />

Create `install-node` as a bash alias!

```bash
alias install-node="curl -sfLS https://install-node.vercel.app | bash -s --"

install-node 14 -y --prefix=$HOME/node14
```
