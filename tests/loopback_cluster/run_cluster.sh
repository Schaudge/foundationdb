#!/bin/bash
set -euo pipefail
trap "kill 0" EXIT
ROOT=`pwd`

function usage {
	echo "Usage 'cd working-directory; ${0} path-to-build-root number-of-clusters-to-start' "
	exit 1
}

if (( $# != 2 )) ; then
	echo Wrong number of arguments
	usage
fi

BUILD=$1

FDB=${BUILD}/bin/fdbserver
if [ ! -f ${FDB} ]; then
	echo "Error: ${FDB} not found!"
	usage
fi

for i in `seq 1 $2` ; do
	DIR=./loopback-cluster-$i
	PORT_PREFIX=${i}50
	rm -rf ${DIR}
	mkdir -p ${DIR}
	CLUSTER_FILE="test$i:testdb$i@127.0.0.1:${PORT_PREFIX}1"
	CLUSTER=${DIR}/fdb.cluster
	echo $CLUSTER_FILE > $CLUSTER
	echo "Starting Cluster: " $CLUSTER_FILE

	for j in 1 2 3; do
		LOG=${DIR}/${j}/log
		DATA=${DIR}/${j}/data
		mkdir -p ${LOG} ${DATA}
		${FDB} -p auto:${PORT_PREFIX}${j} -d $DATA -L $LOG -C $CLUSTER &
	done
	
	CLI="$ROOT/bin/fdbcli -C ${CLUSTER} --exec"
	( sleep 2 ; $CLI "configure new ssd single" ; sleep 1 ; $CLI "status minimal" ) &
done;
sleep 10000000000
