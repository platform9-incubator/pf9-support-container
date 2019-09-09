#!/usr/bin/env bash

set -e
export hostname=$1
export deployname="remote-support-${hostname}"

function usage()
{
	echo "usage: rsh.sh hostname"
}

if [[ -z "${hostname}" ]] ; then
	usage
	exit 1
fi

export HOST_NAME=$1


tmpdir=$(mktemp -d /tmp/rsh.tmp.XXXXX )
bundlepath="${tmpdir}/resources.yaml"

if [[ "${DEBUG}" == "yes" ]] ; then
	echo resources file at ${bundlepath}
	set -x
else
	trap "rm -rf ${tmpdir}" 0 2 3 15
fi

cat rsh-template.yaml | envsubst > ${bundlepath}

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

function pod_running()
{
	podname=$(kubectl -n support get pods | tail -n +2 | grep ${deployname} | awk '{print $1}')
	if [[ -z "${podname}" ]] ; then
		return 1
	fi
	if ! status=$(kubectl -n support get -o jsonpath='{.status.phase}' pod ${podname}) ; then
		return 1
	fi
	if [[ "${status}" != "Running" ]] ; then
		return 1
	fi
}

kubectl apply -f "${bundlepath}" &> /dev/null
wait_until pod_running 4 15
kubectl -n support exec -ti ${podname} -- bash -c "chroot /tmp/root bash -c 'exec bash'"

# clean up
#kubectl delete -f "${bundlepath}" &> /dev/null
