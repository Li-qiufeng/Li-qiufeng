#!/usr/bin/bash
ping -c1 10.18.42.1 &>/dev/null && echo "10.18.42.1 is up" || echo "10.18.42.1 is down!" 
