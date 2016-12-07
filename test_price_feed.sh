#!/bin/bash
# Test price feed.

deduct_percentage=10
price_json=`curl -s https://www.cryptonator.com/api/full/steem-usd 2>/dev/null | grep price`

echo "price_json is: ${price_json}"

# Yes, I'm gonna call perl from bash. Deal with it.
price=`echo ${price_json} | perl -lane 's/.*?(?:price).:.(\d+\.\d{3}).*/$1/; print;'`

echo "Price is: ($price)"

if [[ "$price" = *[[:digit:]]* ]] ; then
	echo "ok 1 - price feed returns a digit"
fi

deduct_percentage=10
price_reduced=`echo ${price_json} | DED_PEC=${deduct_percentage} perl -lane 's/.*?(?:price).:.(\d+\.\d{3}).*/$1/; $_ -= $_*$ENV{DED_PEC}/100; print;'`

echo "10% price_reduced=${price_reduced}"

deduct_percentage=0
price_reduced=`echo ${price_json} | DED_PEC=${deduct_percentage} perl -lane 's/.*?(?:price).:.(\d+\.\d{3}).*/$1/; $_ -= $_*$ENV{DED_PEC}/100; print;'`
echo "0% price_reduced=${price_reduced}"
