#!/bin/bash
#
# cleannode.sh - kill non-privileged processes
#
# run interactively on a single node, or with psh:
# $ psh <nodelist> /soft/admin/cleannode.sh

EXCLUDES=/soft/admin/cleannode.exclude

TARGETS=$(
    /bin/ps -ef --noheader | \
    /bin/grep -v -f ${EXCLUDES} | \
    /bin/awk '{print $1}' | \
    /bin/sort | \
    /usr/bin/uniq \
	);

for val in $TARGETS; {
    /usr/bin/killall -v -u $val;
}

# pause, use SIGKILL for anything leftover
sleep 2

TARGETS=$(
    /bin/ps -ef --noheader | \
    /bin/grep -v -f ${EXCLUDES} | \
    /bin/awk '{print $1}' | \
    /bin/sort | \
    /usr/bin/uniq \
	);

for val in $TARGETS; {
    /usr/bin/killall -v -s 9 -u $val;
}

# always exit 0 so psh doesn't complain
exit 0
