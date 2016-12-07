#!/bin/bash
# Test price feed.

price_json=`curl -s https://www.cryptonator.com/api/full/steem-usd 2>/dev/null | grep price`

echo "price_json is: ${price_json}"

# Yes, I'm gonna call perl from bash. Deal with it.
price=`echo ${price_json} | perl -lane 's/.*?(?:price).:.(\d+\.\d{3}).*/$1/; print;'`

echo "Price is: ($price)"

if [[ "$price" = *[[:digit:]]* ]] ; then
	echo "ok 1 - price feed returns a digit"
fi
