# HostFarmwareTools

## Usage:

Open a terminal and do:
```bash
# clone repo
git clone git@github.com:farmbot-labs/host_farmware_tools
cd host_farmware_tools
mkdir src
mix deps.get
iex -S mix
```

now you can make changes inside of the `src` directory.
Then on the `Farmware` tab on the Farmbot Web App, install a Farmware with a URL like:
`http://192.168.26.29:4001/farmware_installer?directory=src&package=PACKAGENAMEREPLACEME&executable=EXECUTABLENAMEREPLACEME&args[]=arg1&args[]=arg2`
