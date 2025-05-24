#!/bin/bash

find . -name "*.swift" -exec wc -l {} + | sort -nr | head -n 10
