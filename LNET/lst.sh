#!/bin/bash

 set -x
# log directory
LOGDIR=/tmp/lst_logs

LST=echo

# lst stat time interval
LST_DELAY=3

# lst stat duration
LST_DURATION=60

# max concurrency
LST_CONCUR=32

# max brw size
LST_BRW=1024

# vmstat interval
VM_DELAY=3

# clients list, we need 4 or 8 clients at here, please replace them
# i.e: CLIENTS="client1 client2 client3 client4 client5 client6 client7 client8"
CLIENTS="client1@tcp client2@tcp client3@tcp client4@tcp"

# one server
#
# NB:(IMPORTANT)
#    please run this script on server because it's assuming
#    that server is test LST console
#
SERVERS="server@tcp"

rm -rf $LOGDIR
mkdir -p $LOGDIR

NCLIENTS=0
for CLI in $CLIENTS; do
        NCLIENTS=$(($NCLIENTS + 1))
done

NSERVERS=0
for SRV in $SERVERS; do
        NSERVERS=$(($NSERVERS + 1))
done

echo "total number of clients is $NCLIENTS"
echo "total number of servers is $NSERVERS"

export LST_SESSION=$$

cleanup () {
	trap 0; echo killing $1 ... ; kill -9 $1 || true;
}

prep_test() {
	# create session and groups
	local T_SRV=$1
	local T_CLI=$2

	$LST new_session foobar
	$LST add_group cli $T_CLI
	$LST add_group srv $T_SRV
}

done_test() {
	local T_NAME=$1

	# run batch
	$LST run
	sleep 1

	# collect outputs
	$LST stat --delay=$LST_DELAY srv > $LOGDIR/$T_NAME.lst &
	LST_PID=$!

	# sleep for a while and kill stat process
	sleep $LST_DURATION
	
	echo "kill lst stat..."
	cleanup $LST_PID

	# end the session
	$LST end_session
}

# iterate over power2
# NB: the loop will take a few hours (less than 5)

for (( i=1; i <= $NCLIENTS; i=$(($i * 2)))) ; do
    for (( j=1; j <= $i; j=$(($j * 2)))); do

        NCLI=0
        TEST_CLI=

	# get $i clients
        for CLI in $CLIENTS; do
            TEST_CLI="$TEST_CLI $CLI"
	    
            NCLI=$(($NCLI + 1))
            if [ $NCLI = $i ]; then
                break;
            fi
        done

        echo $TEST_CLI

	NSRV=0
	TEST_SRV=

	# get $j servers
        for SRV in $SERVERS; do
                TEST_SRV="$TEST_SRV $SRV"

                NSRV=$(($NSRV + 1))
                if [ $NSRV = $i ]; then
                        break;
                fi
        done

        echo $TEST_SRV

	BRW="read write"

	# brw read & write
	for RW in $BRW; do
			# iterate over 1, 2, 4, 8 threads
	    for (( c=1; c <= $LST_CONCUR; c=$(($c * 2)))) ; do
		TEST_NAME="$RW-${i}cli-${j}srv-${c}concur-dist1:1"
		
		echo "running $TEST_NAME ......"
		
#		vmstat $VM_DELAY > $LOGDIR/$TEST_NAME.vmstat &
        	VMSTAT=$!

		prep_test "$TEST_SRV" "$TEST_CLI"
		$LST add_test --from cli --to srv --loop 9000000 --concurrency=$c --distribute=1:1 brw $RW size=${LST_BRW}k
		done_test $TEST_NAME
		
		cleanup $VMSTAT
	    done
	done
    done
done

for (( i=1; i <= $NCLIENTS; i=$(($i * 2)))) ; do
    for (( j=1; j <= $NSERVERS; j=$(($j * 2)))); do

        NCLI=0
        TEST_CLI=

	# get $i clients
        for CLI in $CLIENTS; do
            TEST_CLI="$TEST_CLI $CLI"
	    
            NCLI=$(($NCLI + 1))
            if [ $NCLI = $i ]; then
                break;
            fi
        done

        echo $TEST_CLI

	NSRV=0
	TEST_SRV=

	# get $j servers
        for SRV in $SERVERS; do
                TEST_SRV="$TEST_SRV $SRV"

                NSRV=$(($NSRV + 1))
                if [ $NSRV = $i ]; then
                        break;
                fi
        done

        echo $TEST_SRV

	BRW="read write"

	# brw read & write
	for RW in $BRW; do
			# iterate over 1, 2, 4, 8 threads
	    for (( c=1; c <= $LST_CONCUR; c=$(($c * 2)))) ; do
		TEST_NAME="$RW-${i}cli-${j}srv-${c}concur-dist1:n"
		
		echo "running $TEST_NAME ......"
		
#		vmstat $VM_DELAY > $LOGDIR/$TEST_NAME.vmstat &
        	VMSTAT=$!

		prep_test "$TEST_SRV" "$TEST_CLI"
		$LST add_test --from cli --to srv --loop 9000000 --concurrency=$c --distribute=1:${j} brw $RW size=${LST_BRW}k
		done_test $TEST_NAME
		
		cleanup $VMSTAT
	    done
	done
    done
done
