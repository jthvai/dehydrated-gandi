#!/usr/bin/env bash

# Hook script mainly adapted from https://www.aaflalo.me/2017/02/lets-encrypt-with-dehydrated-dns-01/
# Forked from https://github.com/tchabaud/lets-encrypt-gandi

# set -x

if [ -z $API_KEY ]; then
  echo "Can't find API key. Please export API_KEY environment variable !"
  exit 1
fi

API_ENDPOINT='https://dns.api.gandi.net/api/v5'

deploy_challenge() {
  local DOMAIN="${1}" RECORD="_acme-challenge.${1}." TOKEN_VALUE=${3}

  # This hook is called once for every domain that needs to be
  # validated, including any alternative names you may have listed.
  #
  # Parameters:
  # - DOMAIN
  #   The domain name (CN or subject alternative name) being validated.
  # - TOKEN_FILENAME
  #   The name of the file containing the token to be served for HTTP
  #   validation. Should be served by your web server as
  #   /.well-known/acme-challenge/${TOKEN_FILENAME}.
  # - TOKEN_VALUE
  #   The token value that needs to be served for validation. For DNS
  #   validation, this is what you want to put in the _acme-challenge
  #   TXT record. For HTTP validation it is the value that is expected
  #   be found in the $TOKEN_FILENAME file.
  if [ ! -z $TOKEN_VALUE ]; then
    echo "Creating DNS TXT field [$RECORD] with value [$TOKEN_VALUE]."
    DATA='{"rrset_name": "'$RECORD'",
      "rrset_type": "TXT",
      "rrset_ttl": 300,
      "rrset_values": ["'$TOKEN_VALUE'"]}'
    curl -s -X POST -d "$DATA" \
      -H "X-Api-Key: $API_KEY" \
      -H "Content-Type: application/json" \
      "$API_ENDPOINT/domains/$DOMAIN/records"
  else
    echo "Something went wrong. Can not find token value to set for record $RECORD."
    exit 1
  fi
}

clean_challenge() {
  local DOMAIN="${1}" RECORD="_acme-challenge.${1}."
  # This hook is called after attempting to validate each domain,
  # whether or not validation was successful. Here you can delete
  # files or DNS records that are no longer needed.
  #
  # The parameters are the same as for deploy_challenge.
  echo "Deleting DNS TXT field [$RECORD] for domain [$DOMAIN]."
  curl -X DELETE -H "Content-Type: application/json" \
    -H "X-Api-Key: $API_KEY" \
    "$API_ENDPOINT/domains/$DOMAIN/records/$RECORD"
}

deploy_cert() {
  local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}" TIMESTAMP="${6}"
  # This hook is called once for each certificate that has been
  # produced. Here you might, for instance, copy your new certificates
  # to service-specific locations and reload the service.
  #
  # Parameters:
  # - DOMAIN
  #   The primary domain name, i.e. the certificate common
  #   name (CN).
  # - KEYFILE
  #   The path of the file containing the private key.
  # - CERTFILE
  #   The path of the file containing the signed certificate.
  # - FULLCHAINFILE
  #   The path of the file containing the full certificate chain.
  # - CHAINFILE
  #   The path of the file containing the intermediate certificate(s).
  # - TIMESTAMP
  #   Timestamp when the specified certificate was created.
  echo "Generated files for ${DOMAIN} : key=[${KEYFILE}] - cert=[${CERTFILE}] - fullchain=[${FULLCHAINFILE}] - chain=[${CHAINFILE}] - timestamp=[${TIMESTAMP}]"
}

unchanged_cert() {
  local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}"
  # This hook is called once for each certificate that is still
  # valid and therefore wasn't reissued.
  #
  # Parameters:
  # - DOMAIN
  #   The primary domain name, i.e. the certificate common
  #   name (CN).
  # - KEYFILE
  #   The path of the file containing the private key.
  # - CERTFILE
  #   The path of the file containing the signed certificate.
  # - FULLCHAINFILE
  #   The path of the file containing the full certificate chain.
  # - CHAINFILE
  #   The path of the file containing the intermediate certificate(s).
  echo "Cert info: keyfile=[${KEYFILE}] - certfile=[${CERTFILE}] - fullchain=[${FULLCHAINFILE}] - chain=[${CHAINFILE}]"
  echo "Cert for domain ${DOMAIN} is still valid. Nothing to do."
}

invalid_challenge() {
  local DOMAIN="${1}" RESPONSE="${2}"
  # This hook is called if the challenge response has failed, so domain
  # owners can be aware and act accordingly.
  #
  # Parameters:
  # - DOMAIN
  #   The primary domain name, i.e. the certificate common
  #   name (CN).
  # - RESPONSE
  #   The response that the verification server returned
  echo "Challenge failed for [${DOMAIN}] - response was [${RESPONSE}]"
}

request_failure() {
  local STATUSCODE="${1}" REASON="${2}" REQTYPE="${3}"
  # This hook is called when a HTTP request fails (e.g., when the ACME
  # server is busy, returns an error, etc). It will be called upon any
  # response code that does not start with '2'. Useful to alert admins
  # about problems with requests.
  #
  # Parameters:
  # - STATUSCODE
  #   The HTML status code that originated the error.
  # - REASON
  #   The specified reason for the error.
  # - REQTYPE
  #   The kind of request that was made (GET, POST...)
  echo "Query [$REQTYPE] failed with error: [$REASON] - status code: [$STATUSCODE]"
}

exit_hook() {
  # This hook is called at the end of a dehydrated command and can be used
  # to do some final (cleanup or other) tasks.
  :
}

HANDLER="$1"; shift
if [[ "${HANDLER}" =~ ^(deploy_challenge|clean_challenge|deploy_cert|unchanged_cert|invalid_challenge|request_failure|exit_hook)$ ]]; then
    "$HANDLER" "$@"
fi
