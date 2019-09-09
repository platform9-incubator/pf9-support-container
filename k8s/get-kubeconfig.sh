#!/usr/bin/env bash

set -e
ns_of_space=$1

if [[ "${DEBUG}" == "yes" ]] ; then
	set -x
fi

function usage()
{
	echo "usage: get-bundle.sh ns_of_space"
}

if [[ -z "${ns_of_space}" ]] ; then
	usage
	exit 1
fi
du_ns="du-${ns_of_space}"

tmpdir=$(mktemp -d /tmp/getkubeconfig.tmp.XXXXX )
space_yaml="${tmpdir}/manifest.json"
region_kv="${tmpdir}/region.txt"
cust_kv="${tmpdir}/customer.txt"
bundlepath="${tmpdir}/resources.yaml"

kubectl -n ${ns_of_space} get -o yaml space ${du_ns} > ${space_yaml}
cust_uuid=$(grep customer_uuid ${space_yaml} |awk '{print $2}')
region_uuid=$(grep region_uuid ${space_yaml} |awk '{print $2}')
pod=$(kubectl -n ${du_ns} get pods|grep -v init|grep Running|grep kplane-clustmgr|awk '{print $1}')
kubectl -n ${du_ns} exec -c kplane-clustmgr ${pod} -- consul kv get -recurse \
	customers/${cust_uuid} 2> /dev/null > ${cust_kv}
fqdn=$(grep ${region_uuid}/fqdn: ${cust_kv} | cut -d: -f2)
username=$(grep service_user/email: ${cust_kv} | cut -d: -f2)
password=$(grep service_user/password: ${cust_kv} | cut -d: -f2)
project=$(grep service_user/project: ${cust_kv} | cut -d: -f2)

OS_AUTH_URL="https://${fqdn}/keystone/v3"
token=`curl -vX POST -H 'Content-Type: application/json' -d "{\"auth\":{\"identity\":{\"methods\":[\"password\"],\"password\":{\"user\":{\"name\":\"$username\",\"domain\":{\"id\":\"default\"},\"password\":\"$password\"}}},\"scope\":{\"project\":{\"name\":\"$project\",\"domain\":{\"id\":\"default\"}}}}}" ${OS_AUTH_URL}/auth/tokens?nocatalog 2>&1 | grep X-Subject-Token | cut -d' ' -f3`
if [[ -z "${token}" ]] ; then
	echo token is empty
	exit 1
fi
# remove newline
token=$(echo $token | tr -d "\r\n")

if [[ "${DEBUG}" == "yes" ]] ; then
	echo fqdn: ${fqdn}
	echo username: ${username}
	echo password: ${password}
	echo project: ${project}
	echo token: ${token}
fi

clusters_json=${tmpdir}/clusters.json
curl -f -H "x-auth-token: ${token}" https://${fqdn}/qbert/v1/clusters 2> /dev/null | python -m json.tool > ${clusters_json}

cluster_name=system
# ensure qbert is up and reports existence of ${cluster_name}
clust_fqdn="${cluster_name}.${fqdn}"
grep ${clust_fqdn} ${clusters_json} &> /dev/null

# download a kubeconfig for the cluster
clust_uuid=$(grep uuid ${clusters_json}|awk '{print $2}'|sed s/\"//g)
kubeconfig="${tmpdir}/${cluster_name}.${fqdn}"

curl -sf -H "x-auth-token: ${token}" \
    https://${fqdn}/qbert/v1/kubeconfig/${clust_uuid} &> ${kubeconfig}

creds="{\"username\":\"${username}\",\"password\":\"${password}\"}"
bearer_token=$(echo -n ${creds} | base64 -w 0)
sed -i -e s/__INSERT_BEARER_TOKEN_HERE__/${bearer_token}/ ${kubeconfig}

echo kubeconfig at ${kubeconfig}