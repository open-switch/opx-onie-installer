# Common utility functions

# Print an error message to stderr
#
# arg1: Error message
# Returns: none
error()
{
    echo "$@" > /dev/stderr
}

# Print an error message and exit with error code
#
# arg1: Error code
# arg2: Error message
# Does not return
abort()
{
    rc=$1
    msg=$2

    error $msg
    exit $rc
}

