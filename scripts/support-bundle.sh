#!/usr/bin/env bash

set -e

echo 'Generating support bundle ...'
chroot /tmp/root bash -c 'LD_LIBRARY_PATH="/opt/pf9/python/pf9-lib:/opt/pf9/python/pf9-hostagent-lib:${LD_LIBRARY_PATH}" PYTHONPATH="/opt/pf9/python/lib/python2.7:${PYTHONPATH}" /opt/pf9/hostagent/bin/python /opt/pf9/hostagent/lib/python2.7/site-packages/datagatherer/datagatherer.py'
echo 'Uploading support bundle ...'
datestr=`date --utc| sed 's/ /-/g'`
du=`grep host= /tmp/root/etc/pf9/hostagent.conf|grep '\.'|cut -d= -f2`
host=`grep host_id /tmp/root/etc/pf9/host_id.conf | awk '{print $3}'`
destfile="bundle-${du}-${host}-${datestr}.tgz"
cd /tmp/root/tmp
aws s3 cp pf9-support.tgz s3://support.pf9.io/bundles/${destfile}
