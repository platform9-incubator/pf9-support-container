#!/usr/bin/env bash

set -e
export hostname=$1

function usage()
{
	echo "usage: get-bundle.sh hostname"
}

if [[ -z "${hostname}" ]] ; then
	usage
	exit 1
fi

export HOST_NAME=$1

if [[ -z "${AWS_ACCESS_KEY_ID}" ]] ; then
	echo AWS_ACCESS_KEY_ID env var must be defined
	exit 1
fi

if [[ -z "${AWS_SECRET_ACCESS_KEY}" ]] ; then
	echo AWS_ACCESS_KEY_ID env var must be defined
	exit 1
fi

export AWS_ACCESS_KEY_ID_BASE64=$(echo -n ${AWS_ACCESS_KEY_ID}|base64 -w 0)
export AWS_SECRET_ACCESS_KEY_BASE64=$(echo -n ${AWS_SECRET_ACCESS_KEY}|base64 -w 0)

tmpdir=$(mktemp -d /tmp/bundle.tmp.XXXXX )
bundlepath="${tmpdir}/resources.yaml"

if [[ "${DEBUG}" == "yes" ]] ; then
	echo bundle resources file at ${bundlepath}
	set -x
else
	trap "rm -rf ${tmpdir}" 0 2 3 15
fi

cat bundle-job-template.yaml | envsubst > ${bundlepath}

# $1 = expression
# $2 = sleep period
# $3 = iterations
function wait_until()
{
    for i in `seq 1 $3`
    do
        eval $1 && return 0
        echo "Waiting for \"$1\" to evaluate to true ..."
        sleep $2
    done
    echo Timed out waiting for \"$1\"
    return 1
}

function no_support_bundle_pods()
{
	if kubectl -n support get pods 2> /dev/null | grep support-bundle; then
		return 1
	fi
}

function job_succeeded()
{
	if ! ok=$(kubectl -n support get -o jsonpath='{.status.succeeded}' job support-bundle) ; then
		return 1
	fi
	if [[ "${ok}" != "1" ]] ; then
		return 1
	fi
}

# delete any existing job
if kubectl -n support delete job support-bundle ; then
	echo deleted old support-bundle job
fi
wait_until no_support_bundle_pods 2 30

kubectl apply -f "${bundlepath}"
wait_until job_succeeded 4 15
pod=$(kubectl -n support get pods |grep support-bundle|awk '{print $1}')
kubectl -n support logs --tail 1 ${pod}

