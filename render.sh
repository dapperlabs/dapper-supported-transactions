#!/bin/sh

# Compute paths to the .env file and the template file
env_file="$1/$2.env"
template_file="$1/$1.cdc.tmpl"

# Populate environment with values from the .env file
export $(cat $env_file | xargs)

# Render the template
envsubst < $template_file
