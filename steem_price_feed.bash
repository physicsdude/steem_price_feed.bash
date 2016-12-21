#!/bin/bash
# Enable error checking (snippet=basherror!)
set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   # set -u : exit the script if you try to use an uninitialised variable
set -o errexit   # set -e : exit the script if any statement returns a non-true return value
set -o verbose   # show commands as they are executed
set -o xtrace    # expand variables
error() {
  echo "Error on or near line ${1}: ${2:-}; exiting with status ${3:-1}"
  exit "${3:-1}"
}
trap 'error ${LINENO}' ERR

# Price feed logic according to Dan:
# Apr 27th
# dan
# 9:11 PM @clayop max frequency 1 hr, min frequency 7 days max change 3%
# 9:11 also introduce some randomness in your queries
# 9:11 that will prevent everyone from updating at the same time
# 9:12 err.. min change 3% :simple_smile:
# 9:12 you can pick what ever percent you want, these are just my opinion on how to minimize network load while still serving the purpose effectively
# 9:23 PM the range for manual intervention should be +/- 50%
# 9:32 PM +/- 50% of HARD CODED long term average
# 9:32 PM I don't think the safety nets should be a percent of a past value...
# 9:32 yes.. so right now between .0005 and .002 SATS
# 9:33 $0.25 and $1.50
# 9:33 something along those lines
# 9:33 if the price moves up we can manually adjust the feeds

# 2016-09-18: added reduction of 10% from price feed, for trying to improve pegging

if ps auxw | grep cli_walle[t] | grep 8092
then
	echo "ok, a cli_wallet appears to be running on port 8092"
else
	echo "make sure you have a wallet running with a command like:"
	echo "cli_wallet -s ws://localhost:8090 -H 127.0.0.1:8092 --rpc-http-allowip=127.0.0.1"
	echo "in a screen session or using supervisorctl or the like"
	exit 42
fi

#min and max price (usd), to exit script for manual intervention
min_bound=0.05
max_bound=10.0
wallet=http://127.0.0.1:8092/rpc

usage () {
    cat 1>&2 <<__EOU__
Usage: $0 -w|--witness <witness> [-m|--min <min-price>] [-M|--max <max-price>] [-r|--rpc-url <rpc-url>] [-d|--deduct-percentage <percentage>] [-v|--vote]
-w sets the name of the witness whose price will be set (and optionally voted
   from).
-m and -M set the absolute maximum and minimum acceptable price. This script
   will exit if the actual price exceeds these bounds. Defaults are $min_bound
   and $max_bound, respectively.
-r specifies the cli_wallet's HTTP-RPC URL. The default is $wallet.
-d deducts percentage of the price feed from original price, write the percentage wanted.
-v will make the given witness vote for the creators of this script, i. e.
   cyrano.witness and steempty. If you have already voted you'll see an error
   message if you vote again. That can be ignored.

Hint: for slightly better security you should keep the cli_wallet locked at all
times. In order to vote, this program needs to unlock the wallet. For this,
create a file named "lock" in the current directory with read permission only
for yourself, and paste the following JSON-RPC command into the "lock" file:
{"id":0,"method":"unlock","params":["<your_password>"]}
Obviously, you need to replace the placeholder with your actual password.
__EOU__
    exit 1
}

unlock () {
    if [ -r lock ]; then
	echo -n "Unlocking wallet..."
	curl -s --data-ascii @lock "$wallet"
	echo ""
    else
	echo -n "No lock file..."
    fi
}

relock () {
    if [ -r lock ]; then
	echo -n "Re-locking wallet..."
	curl -s --data-ascii '{"id":0,"method":"lock","params":[]}' "$wallet"
	echo ""
    fi
}

vote () {
    unlock
    curl -s --data-ascii '{"method":"vote_for_witness","params":["'"$account"'","cyrano.witness",true,true],"jsonrpc":"2.0","id":0}' "$wallet"
    curl -s --data-ascii '{"method":"vote_for_witness","params":["'"$account"'","steempty",true,true],"jsonrpc":"2.0","id":0}' "$wallet"
    relock
}

deduct_percentage=0
vote="no"
max_delay_minutes=60
while [ $# -gt 0 ]; do
    case "$1" in
	-w|--witness) account="$2";   shift; ;;
	-x|--max-delay-minutes)  max_delay_minutes="$2"; shift; ;;
	-m|--min)     min_bound="$2"; shift; ;;
	-M|--max)     max_bound="$2"; shift; ;;
	-r|--rpc-url) wallet="$2";    shift; ;;
	-d|--deduct-percentage)  deduct_percentage="${2//[^0-9]/}";   shift; ;;
	-v|--vote)    vote="yes";       ;;
	*)	      usage;	      ;;
    esac
    shift
done

if [ -z "$account" ]; then usage; fi
if [ "$vote" = yes ]; then vote; fi

# Avoid problems with decimal separator
export LANG=C

get_wallet_price () {
    curl --data-ascii '{"id":0,"method":"get_witness","params":["'"$account"'"]}' \
	 -s "$wallet" \
      | sed "s=[{,]=&$'\n'=g" \
      | grep -A 2 'sbd_exchange_rate' \
      | grep '"base"' \
      | cut -d\" -f 4 \
      | sed 's= SBD==;s= STEEM=='
}

get_last_update () {
    local jtime="$(curl --data-ascii '{"id":0,"method":"get_witness","params":["'"$account"'"]}' \
			-s "$wallet" \
		     | sed "s=[{,]=&$'\n'=g" \
		     | grep '"last_sbd_exchange_update"' \
		     | cut -d\" -f 4 \
		     | sed 's= SBD==;s= STEEM==')"
    date --date "${jtime}Z" +%s
}

function get_price {
  while true ; do 
    while true ; do
       price_json=`curl -s https://www.cryptonator.com/api/full/steem-usd 2>/dev/null | grep price`
       #echo "price_json is: ${price_json}"
       # Yes, I'm gonna call perl from bash. Deal with it.
       # Removes dependency on bc and doesn't require prinf which caused an error in bash strict mode in some cases.
       price=`echo ${price_json} | DED_PEC=${deduct_percentage} perl -lane 's/.*?(?:price).:.(\d+\.\d{3}).*/$1/; $_ -= $_*$ENV{DED_PEC}/100; print;'`
       ret=$?
       [ "$ret" -eq 0 ] && break
       (>&2 echo "Price feed fail. API returned: (${price_json:-})")
       sleep 1m
    done
    #price source and way to calculate will probably need to be changed in the future
    if [[ "$price" = *[[:digit:]]* ]] ; then
      break
    fi
    sleep 1m
  done
  echo "${price:-}"
}

init_price="`get_wallet_price`"
if [ "$init_price" = "" ]; then
    echo "Empty price - wallet not running?" 1>&2
    exit 1
fi
last_feed="`get_last_update`"

while true ; do
  #check price
  price="`get_price`"
  echo "price: $price" 
  if [ "$price" = 0.000 ]; then
    echo "Zero price - ignoring"
    price="$init_price"
  fi
  #check persentage
  price_permillage="`echo "scale=3; (${price} - ${init_price}) / ${price} * 1000" | bc | tr -d '-'`"
  price_permillage="${price_permillage%.*}"
  now="`date +%s`"
  update_diff="$(($now-$last_feed))"
  #check bounds, exit script if more than 50% change, or minimum/maximum price bound
  if [ "`echo "scale=3;$price>$max_bound" | bc`" -gt 0 -o "`echo "scale=3;$price<$min_bound" | bc`" -gt 0 ] ; then
     echo "manual intervention (bound) $init_price $price, exiting"
     exit 1
  fi 
  if [ "$price_permillage" -gt 500 ] ; then
     echo "manual intervention (percent) $init_price $price, exiting"
     exit 1
  fi 
  #check if to send update (once per max_delay_minutes maximum, 0.1% change minimum, 1/24 hours minimum)
  max_delay_seconds=$(( ${max_delay_minutes} * 60 ))
  if [ "$price_permillage" -gt 1 -a "$update_diff" -gt ${max_delay_seconds} \
	-o "$update_diff" -gt 86400 ] ; then
    init_price="$price"
    last_feed="$now"
    unlock
    echo "sending feed ${price_permillage}/10% price: $price"
    curl --data-ascii '{"method":"publish_feed","params":["'"$account"'",{"base":"'"$price"' SBD","quote":"1.000 STEEM"},true],"jsonrpc":"2.0","id":0}' \
	 -s "$wallet"
    relock
  fi
  echo "${price_permillage}/10% | price: $price | time since last post: $update_diff"
  wait="$(($RANDOM % ${max_delay_minutes}))"
  echo -n "Waiting until "
  date --date=@"$(( $wait * 60 + $(date +%s) ))"
  sleep "${wait}m"
done
