#!/usr/bin/env bash

#
# Example how to deploy a DNS challenge using linode CLI (https://github.com/linode/cli)
#

set -e
set -u
set -o pipefail
umask 077

updatefile="$(mktemp)"

HOOK=$1
HOST=$2
CHALLENGE=$4
LINODECLI="/usr/local/bin/linode"
ACME_STRING="_acme-challenge"
WAIT_FOR_DNS=20
done="no"

if [[ "$1" = "deploy_challenge" ]]; then
    printf "domain record-create %s TXT _acme-challenge --ttl 300 --target %s\n" "$HOST" "$CHALLENGE"
    printf "domain record-create %s TXT _acme-challenge --ttl 300 --target %s" "$HOST" "$CHALLENGE" > "${updatefile}"
    $LINODECLI `cat ${updatefile}`

# ensure all NS got the challenge
ok=0
# get all authoritative name servers
for ns in $(dig +noall +authority "${2}" | sed -e "s/^.*\t//g"); do
#for ns in "8.8.8.8"; do
        timestamp=$(date "+%s")
        dig_result="failed."
        echo -n "    + Checking challenge on $ns.. "
        # try max. 5 minutes
        while [ $(($(date "+%s")-$timestamp)) -lt $(($WAIT_FOR_DNS * 60)) ]; do
		msg="$(dig +short "${ACME_STRING}.${HOST}" TXT @${ns} 2>/dev/null)"
                if [ $? -eq 0 -a $(echo "$msg" | grep $CHALLENGE | wc -l) -gt 0 ]; then
                        dig_result="ok."
                        let "ok+=1"
                        break;
                fi
                sleep 1.5
        done
        echo "$dig_result"
done
# if there was no answer or just errors from dig exit non-zero
[ $ok -eq 0 ] && exit 1

    done="yes"
fi

if [[ "$1" = "clean_challenge" ]]; then
    printf "domain record-delete %s TXT _acme-challenge --match %s\n" "$HOST" "$CHALLENGE"
    printf "domain record-delete %s TXT _acme-challenge --match %s" "$HOST" "$CHALLENGE" > "${updatefile}"
    $LINODECLI `cat ${updatefile}`
    done="yes"
fi

if [[ "${1}" = "deploy_cert" ]]; then
    # do nothing for now
    printf "deploy_cert - do nothing for now..."
    done="yes"
fi

rm -f "${updatefile}"

if [[ ! "${done}" = "yes" ]]; then
    echo Unkown hook "$HOOK"
    exit 1
fi

exit 0
