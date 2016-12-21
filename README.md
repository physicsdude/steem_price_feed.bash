# Summary

You can use this script to run an automated Steem price feed as a steem witness.

## Start a command line wallet

You first need to be running a cli_wallet with a command like this (using a screen session or the like).

```bash
cli_wallet -s ws://localhost:8090 -H 127.0.0.1:8092 --rpc-http-allowip=127.0.0.1
```

There's a convenience script called start_cli_wallet_for_price_feed.sh which contains this command.

As described in the steem_price_feed.bash usage output

"for slightly better security you should keep the cli_wallet locked at all
times. In order to vote, this program needs to unlock the wallet. For this,
create a file named "lock" in the current directory with read permission only
for yourself, and paste the following JSON-RPC command into the "lock" file:
{"id":0,"method":"unlock","params":["<your_password>"]}
Obviously, you need to replace the placeholder with your actual password."

## Set up the .config file

You should create a config file in the place shown below with PRICE_MAXTIME, PRICE_WITNESS, and PRICE_EMAIL

```bash
 $ cd $HOME
 $ mkdir .steem_price_feed.bash
 $ vim $HOME/.steem_price_feed_bash/.config
```

Add the following lines

```bash
 export PRICE_WITNESS='your-witness-name'
 export PRICE_MAXTIME=60
 export PRICE_EMAIL='email-you-want-to-get-alerts-at@example.com'
```

Exit, and save.

### Run the price feed

The main price feed script has error reporting mechanisms and will exit if anything seems to go wrong.

For this reason, there is a wrapper script called ./run.sh.
You can run it like this, e.g. from a screen session

```bash
 $ ./run.sh
```

This is the main script you should run because it'll re-start the main script and (if you supplied an email) email you info about the error.

#### Credits

steem_price_feed.bash is based on steem_price_feed.bash by https://steemit.com/@steempty. Thank you steempty.

https://steemit.com/witness-category/@steempty/bash-script-for-price-feed-task-of-witnesses

According to steempty's post, improvements were made by https://steemit.com/@cyrano.witness. Thank you cyrano.witness.

Also referenced here https://steemit.com/witness-category/@bitcalm/how-to-become-a-witness

Commits made by nobody@example.com in late 2016 are courtesy of https://steemit.com/@nonlinearone

This includes the new files run.sh, test_price_feed.sh, start_cli_wallet_for_price_feed.sh, and this README.md.
