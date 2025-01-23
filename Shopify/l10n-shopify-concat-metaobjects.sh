#!/bin/bash
ls -1 *.json | sort -n | xargs cat | jq -c > metaobjects.txt