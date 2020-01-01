#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright 2018 Thomas Chabaud, GPL v3.0
# Copyright 2020 Elias Yuan, GPL v3.0+
#   Refer to LICENSE for the full text. You may also acquire a copy from
#   gitlab.com/jthvai/licenses/raw/master/GPL-3.0.txt
#
# OS:
#   Only tested on Arch Linux x86_64
#
# Synopsis:
#   Bash wrapper to create and renew Let's Encrypt SSL certificates
#   using the dehydrated (https://github.com/lukas2511/dehydrated) ACME
#   client, the DNS-01 challenge, and Gandi's LiveDNS API.
#
#   Forked from https://github.com/tchabaud/lets-encrypt-gandi.
#
#   This adaptation does not use the --cron option of dehydrated, and
#   instead manually generates certificate requests - for the benefit of
#   my obsession with elliptical curve keys.
#
# Dependencies:
#   bash
#   coreutils
#   curl
#   openssl
#
# Notes:
#   A Gandi LiveDNS API key is also required.
#   See https://doc.livedns.gandi.net/#step-1-get-your-api-key
#
#=======================================================================

# Absolute path this script is in
export SCRIPT_PATH="$(dirname $(readlink --canonicalize $0))"
echo "Running from directory $SCRIPT_PATH"

export WORKDIR="$SCRIPT_PATH/workdir"
if [ ! -d $WORKDIR ]; then
  mkdir $SCRIPT_PATH/workdir
fi
echo "Using $WORKDIR to store configuration."

if [ -f $WORKDIR/env ]; then
  echo "Sourcing $WORKDIR/env"
  source $WORKDIR/env
fi

if [ -z $API_KEY ]; then
  echo "Can't find API key. Please export API_KEY environment variable!"
  exit 1
fi

if [ -z $DOMAIN ]; then
  echo "Please specify a domain name or a wildcard (*.your.domain.tld)"
  echo "using DOMAIN environment variable."
  exit 1
fi

DOMAIN_FILE="$WORKDIR/domains.txt"
if [ ! -f $DOMAIN_FILE ]; then
  DOMAIN_WITHOUT_STAR=$(echo $DOMAIN |tr -d '*' |tr '\.' '_')
  echo "$DOMAIN > star-$DOMAIN_WITHOUT_STAR" > $DOMAIN_FILE
fi

CONFIG_FILE="$WORKDIR/config"
if [ ! -f $CONFIG_FILE ]; then
  echo "Creating configuration file ..."
  cat > $CONFIG_FILE <<EOF
# See https://github.com/lukas2511/dehydrated/blob/master/docs/examples/config
# for all possible options
IP_VERSION=4
# Path to certificate authority (default: https://acme-v02.api.letsencrypt.org/directory)
CA="https://acme-v02.api.letsencrypt.org/directory"
#CA="https://acme-staging-v02.api.letsencrypt.org/directory"
CHALLENGETYPE="dns-01"
HOOK="$SCRIPT_PATH/hook.sh"
AUTO_CLEANUP="yes"
EOF
fi

DEHYDRATED="$SCRIPT_PATH/dehydrated"
if [ ! -f $DEHYDRATED ]; then
  curl --output $DEHYDRATED \
    'https://raw.githubusercontent.com/lukas2511/dehydrated/master/dehydrated'
  chmod 700 $DEHYDRATED
  echo "Successfully downloaded Dehydrated script to $DEHYDRATED"
fi

if [ -z $CERT_PRIVKEY -o ! -f $CERT_PRIVKEY ]; then
  openssl genrsa -out $WORKDIR/privkey.pem 4096
  chmod 400 $WORKDIR/privkey.pem
  export CERT_PRIVKEY="$WORKDIR/privkey.pem"
fi

export OPENSSL_REQ="$WORKDIR/req.csr"
if [ -n $OPENSSL_CONFIG -a -f $OPENSSL_CONFIG ]; then
  openssl req -new -key $CERT_PRIVKEY -out $OPENSSL_REQ \
    -subj "/CN=$DOMAIN/" -config $OPENSSL_CONFIG
else
  openssl req -new -key $CERT_PRIVKEY -out $OPENSSL_REQ \
    -subj "/CN=$DOMAIN/"
fi

if [ ! -d $WORKDIR/accounts ]; then
  echo "Account not found, registering to Let's Encrypt ..."
  $DEHYDRATED --register --accept-terms --config $CONFIG_FILE
fi

$DEHYDRATED --signcsr $OPENSSL_REQ --full-chain \
  --config $CONFIG_FILE \
  > $WORKDIR/full.crt
