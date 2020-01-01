#!/usr/bin/env sh

# Absolute path to this script
SCRIPT=$(readlink -f "$0")

# Absolute path this script is in
SCRIPT_PATH=$(dirname "${SCRIPT}")

echo "Running from directory ${SCRIPT_PATH}"

if [ -z "${WORKDIR}" -o ! -d "${WORKDIR}" ]; then
  echo "Please specify an existing directory using WORKDIR environment variable."
  echo "This directory will be used to save certs data and configuration."
  exit 1
fi
echo "Using ${WORKDIR} to store configuration."

if [ -z "${API_KEY}" ]; then
  echo "Can't find API key. Please export API_KEY environment variable !"
  exit 1
fi

DOMAIN_FILE="${WORKDIR}/domains.txt"
if [ ! -f "${DOMAIN_FILE}" ]; then
  if [ -z "${DOMAIN}" ]; then
    echo "Please specify a domain name or a wildcard (*.your.domain.tld) using DOMAIN environment variable."
    exit 1
  fi
  DOMAIN_WITHOUT_STAR=$(echo "${DOMAIN}" |tr -d '*' |tr '\.' '_')
  echo "${DOMAIN} > star-${DOMAIN_WITHOUT_STAR}" > "${DOMAIN_FILE}"
fi

CONFIG_FILE="${WORKDIR}/config"
if [ ! -f "${CONFIG_FILE}" ]; then
  echo "Creating configuration file ..."
  cat > "${CONFIG_FILE}" <<EOF
# See https://github.com/lukas2511/dehydrated/blob/master/docs/examples/config
# for all possible options
IP_VERSION=4
# Path to certificate authority (default: https://acme-v02.api.letsencrypt.org/directory)
CA="https://acme-v02.api.letsencrypt.org/directory"
#CA="https://acme-staging-v02.api.letsencrypt.org/directory"
CHALLENGETYPE="dns-01"
HOOK="${SCRIPT_PATH}/hook.sh"
AUTO_CLEANUP="yes"
EOF
fi

DEHYDRATED_HOME="https://github.com/lukas2511/dehydrated/raw/master/dehydrated"
DEHYDRATED_FILE="${SCRIPT_PATH}/dehydrated"
if [ ! -f "${DEHYDRATED_FILE}" ]; then
  wget -O "${DEHYDRATED_FILE}" "${DEHYDRATED_HOME}"
  chmod u+x "${DEHYDRATED_FILE}"
  echo "Successfully downloaded Dehydrated script to ${DEHYDRATED_FILE}"
fi

ACCOUNT_DIR="${WORKDIR}/accounts"
if [ ! -d "${ACCOUNT_DIR}" ]; then
  echo "Account not found, registering to Let's Encrypt ..."
  ${DEHYDRATED_FILE} --register --accept-terms -f "${WORKDIR}/config"
fi

${DEHYDRATED_FILE} -c -f "${WORKDIR}/config"
