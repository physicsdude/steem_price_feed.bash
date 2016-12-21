#!/bin/bash

echo "Make sure to do this in a screen session or the like"

cd $HOME

cli_wallet -s ws://localhost:8090 -H 127.0.0.1:8092 --rpc-http-allowip=127.0.0.1
