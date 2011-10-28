#!/bin/bash

 set -x
# log directory
LOGDIR=/tmp/lst_logs

LST=echo

# lst stat time interval
LST_DELAY=60

# lst stat duration
LST_DURATION=65

# max concurrency
LST_CONCUR=32

# max brw size
LST_BRW=1024

# vmstat interval
VM_DELAY=3

# clients list, we need 4 or 8 clients at here, please replace them
# i.e: CLIENTS="client1 client2 client3 client4 client5 client6 client7 client8"
# sal compute
CLIENTS="149.165.224.193@tcp 149.165.224.194@tcp 149.165.224.195@tcp 149.165.224.196@tcp 149.165.224.197@tcp 149.165.224.198@tcp 149.165.224.199@tcp 149.165.224.200@tcp 149.165.224.201@tcp 149.165.224.202@tcp 149.165.224.203@tcp 149.165.224.204@tcp 149.165.224.205@tcp 149.165.224.206@tcp 149.165.224.207@tcp 149.165.224.208@tcp 149.165.224.209@tcp 149.165.224.210@tcp 149.165.224.211@tcp 149.165.224.212@tcp 149.165.224.213@tcp 149.165.224.214@tcp 149.165.224.215@tcp 149.165.224.216@tcp 149.165.224.217@tcp 149.165.224.218@tcp 149.165.224.219@tcp 149.165.224.220@tcp 149.165.224.221@tcp 149.165.224.222@tcp"

# ida compute 
#CLIENTS="149.165.224.65@tcp 149.165.224.66@tcp 149.165.224.67@tcp 149.165.224.68@tcp 149.165.224.69@tcp 149.165.224.70@tcp 149.165.224.71@tcp 149.165.224.72@tcp 149.165.224.73@tcp 149.165.224.74@tcp 149.165.224.75@tcp 149.165.224.76@tcp 149.165.224.77@tcp 149.165.224.78@tcp 149.165.224.79@tcp 149.165.224.80@tcp 149.165.224.81@tcp 149.165.224.82@tcp 149.165.224.83@tcp 149.165.224.84@tcp 149.165.224.85@tcp 149.165.224.86@tcp 149.165.224.87@tcp 149.165.224.88@tcp 149.165.224.89@tcp 149.165.224.90@tcp 149.165.224.91@tcp 149.165.224.92@tcp 149.165.224.93@tcp 149.165.224.94@tcp"

# one server
#
# NB:(IMPORTANT)
#    please run this script on server because it's assuming
#    that server is test LST console
#
# sal storage
SERVERS="149.165.224.235@tcp 149.165.224.236@tcp 149.165.224.237@tcp 149.165.224.238@tcp 149.165.224.239@tcp 149.165.224.240@tcp 149.165.224.241@tcp 149.165.224.242@tcp 149.165.224.243@tcp 149.165.224.244@tcp 149.165.224.245@tcp 149.165.224.246@tcp 149.165.224.247@tcp 149.165.224.248@tcp 149.165.224.249@tcp 149.165.224.250@tcp"

# ida storage
#SERVERS="149.165.224.107@tcp 149.165.224.108@tcp 149.165.224.109@tcp 149.165.224.110@tcp 149.165.224.111@tcp 149.165.224.112@tcp 149.165.224.113@tcp 149.165.224.114@tcp 149.165.224.115@tcp 149.165.224.116@tcp 149.165.224.117@tcp 149.165.224.118@tcp 149.165.224.119@tcp 149.165.224.120@tcp 149.165.224.121@tcp 149.165.224.122@tcp"

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
	
#	echo $T_CLI
#	echo $T_SRV

	$LST new_session foobar
	$LST add_group cli $T_CLI
	$LST add_group srv $T_SRV
}

done_test() {
	local T_NAME=$1
	local T_SRV=$2
	local T_CLI=$3

	# run batch
	$LST run
	sleep 1

	# collect outputs
	$LST stat --delay=$LST_DELAY $T_SRV > $LOGDIR/$T_NAME.srv &
	$LST stat --delay=$LST_DELAY $T_CLI > $LOGDIR/$T_NAME.cli &
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
    if [ $i = 2 ] || [ $i = 4 ]; then
	continue;
    fi
    for (( j=1; j <= $i; j=$(($j * 2)))); do
	if [ $j = 2 ]; then
	    continue;
	fi

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
                if [ $NSRV = $j ]; then
                        break;
                fi
        done

        echo $TEST_SRV

	BRW="write"

	# brw read & write
	for RW in $BRW; do
			# iterate over 1, 2, 4, 8 threads
	    for (( c=1; c <= $LST_CONCUR; c=$(($c * 2)))) ; do
		if [ $c = 2 ] || [ $c = 4]; then
		    continue;
		fi
		TEST_NAME="$RW-${i}cli-${j}srv-${c}concur-dist1:1"
		
		echo "running $TEST_NAME ......"
		
#		vmstat $VM_DELAY > $LOGDIR/$TEST_NAME.vmstat &
        	VMSTAT=$!

		prep_test "$TEST_SRV" "$TEST_CLI"
		$LST add_test --from cli --to srv --loop 9000000 --concurrency=$c --distribute=1:1 brw $RW size=${LST_BRW}k
		done_test $TEST_NAME "$TEST_SRV" "$TEST_CLI"
		
		cleanup $VMSTAT
	    done
	done
    done
done

# special case of 30 clients

BRW="write"

	# brw read & write
for RW in $BRW; do
	# iterate over 1, 2, 4, 8 threads
    for (( c=1; c <= $LST_CONCUR; c=$(($c * 2)))) ; do
	if [ $c = 2 ] || [ $c = 4]; then
	    continue;
	fi
	TEST_NAME="$RW-30cli-16srv-${c}concur-dist1:1"
		
	echo "running $TEST_NAME ......"
	
#		vmstat $VM_DELAY > $LOGDIR/$TEST_NAME.vmstat &
        VMSTAT=$!

	prep_test "$SERVERS" "$CLIENTS"
	$LST add_test --from cli --to srv --loop 9000000 --concurrency=$c --distribute=1:1 brw $RW size=${LST_BRW}k
	done_test $TEST_NAME "$SERVERS" "$CLIENTS"
	
	cleanup $VMSTAT
    done
done

for (( i=1; i <= $NCLIENTS; i=$(($i * 2)))) ; do
    if [ $i = 2 ] || [ $i = 4 ]; then
	continue;
    fi
    for (( j=8; j <= 12; j=$(($j + 2)))); do

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
                if [ $NSRV = $j ]; then
                        break;
                fi
        done

        echo $TEST_SRV

	BRW="write"

	# brw read & write
	for RW in $BRW; do
			# iterate over 1, 2, 4, 8 threads
	    for (( c=1; c <= $LST_CONCUR; c=$(($c * 2)))) ; do
		if [ $c = 2 ] || [ $c = 4]; then
		    continue;
		fi
		TEST_NAME="$RW-${i}cli-${j}srv-${c}concur-dist1:n"
		
		echo "running $TEST_NAME ......"
		
#		vmstat $VM_DELAY > $LOGDIR/$TEST_NAME.vmstat &
        	VMSTAT=$!

		prep_test "$TEST_SRV" "$TEST_CLI"
		$LST add_test --from cli --to srv --loop 9000000 --concurrency=$c --distribute=1:${j} brw $RW size=${LST_BRW}k
		done_test $TEST_NAME "$TEST_SRV" "$TEST_CLI"
		
		cleanup $VMSTAT
	    done
	done
    done
done

# special case of 30 clients

BRW="write"

	# brw read & write
for RW in $BRW; do
	# iterate over 1, 2, 4, 8 threads
    for (( c=1; c <= $LST_CONCUR; c=$(($c * 2)))) ; do
	if [ $c = 2 ] || [ $c = 4]; then
	    continue;
	fi
	TEST_NAME="$RW-30cli-16srv-${c}concur-dist1:1"
		
	echo "running $TEST_NAME ......"
	
#		vmstat $VM_DELAY > $LOGDIR/$TEST_NAME.vmstat &
        VMSTAT=$!

	prep_test "$SERVERS" "$CLIENTS"
	$LST add_test --from cli --to srv --loop 9000000 --concurrency=$c --distribute=1:16 brw $RW size=${LST_BRW}k
	done_test $TEST_NAME "$SERVERS" "$CLIENTS"
	
	cleanup $VMSTAT
    done
done
