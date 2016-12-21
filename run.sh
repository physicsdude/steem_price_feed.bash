#!/bin/bash
set -o verbose   # show commands as they are executed
set -o xtrace    # expand variables

MAILCMD=`which mail`

if [[ -f "${HOME}/.steem_price_feed_bash/.config" ]]; then
	source $HOME/.steem_price_feed_bash/.config
else
	echo "You need to set up a .config - see README.md"
	exit 137
fi

until ./steem_price_feed.bash; do
    MESSAGE="Server './steem_price_feed.bash' crashed with exit code $?.  Respawning.."
    echo ${MESSAGE} >&2
    if [  -n "${PRICE_EMAIL}" ]; then
        echo ${MESSAGE} | ${MAILCMD} -s "${MESSAGE}" ${PRICE_EMAIL}
    fi
    sleep 60
done
