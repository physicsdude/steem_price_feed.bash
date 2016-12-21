#!/bin/bash
source .config

until ./steem_price_feed.bash; do
    MESSAGE="Server './steem_price_feed.bash' crashed with exit code $?.  Respawning.."
    echo $MESSAGE >&2
    if [ ${PRICE_EMAIL:-} ]; then
        echo $MESSAGE | mail -s ${PRICE_EMAIL}
    fi
    sleep 1
done
