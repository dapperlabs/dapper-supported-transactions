#!/bin/sh

# Compute paths to the .env file and the template file
env_file="$1/$2.env"
template_file="$1/$1.cdc.tmpl"
output_file="$1/$1.cdc"

# Populate environment with values from the .env file
export $(cat $env_file | xargs)

# Render the template
envsubst < $template_file > $output_file

# Output the rendered script hash
sha256sum $output_file
