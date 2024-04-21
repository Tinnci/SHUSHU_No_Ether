#!/bin/bash

DEPENDENCIES=(curl nc grep awk cut date mkdir)
MISSING_DEPS=0

echo "Checking for missing dependencies:"

for cmd in "${DEPENDENCIES[@]}"; do
    if ! command -v $cmd >/dev/null 2>&1; then
        echo "- $cmd is missing."
        MISSING_DEPS=$((MISSING_DEPS+1))
    else
        echo "+ $cmd is installed."
    fi
done

if [ $MISSING_DEPS -eq 0 ]; then
    echo "All dependencies are installed."
else
    echo "Some dependencies are missing. Please install them before running the script."
fi

exit $MISSING_DEPS