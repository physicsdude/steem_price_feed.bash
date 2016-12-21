You can use this script to run an automated Steem price feed as a steem witness.

You first need to be running a cli_wallet with a command like this (using a screen session or the like).

cli_wallet -s ws://localhost:8090 -H 127.0.0.1:8092 --rpc-http-allowip=127.0.0.1

There's a convenience script called start_cli_wallet_for_price_feed.sh which contains this command.

As described in the steem_price_feed.bash usage output

"for slightly better security you should keep the cli_wallet locked at all
times. In order to vote, this program needs to unlock the wallet. For this,
create a file named "lock" in the current directory with read permission only
for yourself, and paste the following JSON-RPC command into the "lock" file:
{"id":0,"method":"unlock","params":["<your_password>"]}
Obviously, you need to replace the placeholder with your actual password."

You should create a config file in the place shown below with PRICE_MAXTIME, PRICE_WITNESS, and PRICE_EMAIL

 $ cd $HOME
 $ mkdir .steem_price_feed.bash
 $ vim $HOME/.steem_price_feed_bash/.config

Add the following lines

 export PRICE_WITNESS='your-witness-name'
 export PRICE_MAXTIME=60
 export PRICE_EMAIL='email-you-want-to-get-alerts-at@example.com'

Exit, and save.

The main price feed script has error reporting mechanisms and will exit if anything seems to go wrong.

For this reason, there is a wrapper script called ./run.sh

This is the main script you should run because it'll re-start the main script and (if you supplied an email) email you info about the error.
