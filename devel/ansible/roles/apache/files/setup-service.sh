#!/bin/sh

set -e

HOST_NAME="$1"
APP_NAME="$2"
IPA_SERVER="$3"
REALM="$4"

PRINCIPAL="HTTP/$HOST_NAME"
DELEGATION="${APP_NAME}-delegation"

ipa service-find $PRINCIPAL &> /dev/null || ipa service-add $PRINCIPAL --force

# Create delegation rule

ipa servicedelegationrule-find $DELEGATION &> /dev/null || ipa servicedelegationrule-add $DELEGATION

ipa servicedelegationrule-show $DELEGATION | grep "Member principals:" | grep -qs $PRINCIPAL || (
	ipa servicedelegationrule-add-member --principals=$PRINCIPAL $DELEGATION
)

# Delegate for HTTP

ipa servicedelegationtarget-find ipa-http-delegation-targets &> /dev/null || ipa servicedelegationtarget-add ipa-http-delegation-targets

ipa servicedelegationtarget-show ipa-http-delegation-targets | grep "Member principals:" | grep -qs HTTP/${IPA_SERVER} || (
	ipa servicedelegationtarget-add-member ipa-http-delegation-targets --principals=HTTP/${IPA_SERVER}@${REALM}
)

ipa servicedelegationrule-show $DELEGATION | grep "Allowed Target:" | grep -qs ipa-http-delegation-targets || (
	ipa servicedelegationrule-add-target --servicedelegationtargets=ipa-http-delegation-targets $DELEGATION
)
