#!/bin/bash

# Create a JSON file, with version information for all installed OPX packages

OUTFILE=/etc/opx/manifest.json
echo '{ "packages": [' >$OUTFILE
i=0
sep=''
lim=3
for x in `dpkg-query -W -f '${db:Status-Abbrev} ${Package} ${Version}\n' '*opx*'`
do
    if [ $i -eq 0 ]
    then
	status="$x"
	if [ "$status" = ii ]
	then
	    lim=3
	else
	    lim=2
	fi
    elif [ $i -eq 1 ]
    then
	name="$x"
    elif [ "$status" = ii ]
    then
	echo "$sep{ \"name\": \"$name\", \"version\": \"$x\" }" >>$OUTFILE
    fi
    
    i=$(($i + 1))
    if [ $i -ge $lim ]
    then
	i=0
	sep=', '
    fi
done
echo '] }' >>$OUTFILE
