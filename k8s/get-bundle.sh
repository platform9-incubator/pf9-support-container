#!/usr/bin/env bash

export hostname=$1

function usage()
{
	echo "usage: get-bundle.sh hostname"
}

if [[ -z "${hostname}" ]] ; then
	usage
	exit 1
fi

if [[ -z "${AWS_ACCESS_KEY_ID}" ]] ; then
	echo AWS_ACCESS_KEY_ID env var must be defined
	exit 1
fi

if [[ -z "${AWS_SECRET_ACCESS_KEY}" ]] ; then
	echo AWS_ACCESS_KEY_ID env var must be defined
	exit 1
fi


