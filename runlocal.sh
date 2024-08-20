#!/bin/sh

if [ -n "$1" ]; then
    extra="--extra-vars=@$1"
elif [ -f "settings.yaml" ]; then
    extra="--extra-vars=@settings.yaml"
fi

ansible-playbook --connection=local -i $(hostname -s), $extra playbook.yaml -D
