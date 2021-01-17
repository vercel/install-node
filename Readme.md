# install-node.vercel.app

Simple one-liner shell script that installs official Node.js binaries

<img width="1300" src="https://user-images.githubusercontent.com/71256/104836670-75b98b00-5864-11eb-8fd0-4747495e3867.png">

Create `install-node` as a bash alias!

```bash
alias install-node="curl -s https://install-node.vercel.app | bash -s --"

install-node 14 -y --prefix=$HOME/node14
```
