#!/usr/bin/env bash

set -e

unset PASSWORD_STORE_SIGNING_KEY
unset PASSWORD_STORE_DIR
unset PASSWORD_STORE_EXTENSIONS_DIR
unset PASSWORD_STORE_ENABLE_EXTENSIONS
TEST_ENV_DIR="${PWD}/test_env"
export PASSWORD_STORE_DIR="${TEST_ENV_DIR}/password-store/db"
export PASSWORD_STORE_EXTENSIONS_DIR="${TEST_ENV_DIR}/password-store/extensions"
export PASSWORD_STORE_ENABLE_EXTENSIONS="true"
export GNUPGHOME="${TEST_ENV_DIR}/gnupg"
PGP_DIR="${TEST_ENV_DIR}/pgp"
PGP_PRIV_KEY="${PGP_DIR}/masterkey.asc"
PGP_KEY_ID="2C752423906F4CE73091C2077B18C1616AAA9C35"
#
# Create the necessary directories.
#
mkdir -p "${PASSWORD_STORE_DIR}"
mkdir -p "${PASSWORD_STORE_EXTENSIONS_DIR}"
#
# Only the last created directory should have these permissions.
# shellcheck disable=SC2174
#
mkdir -pm 0700 "${GNUPGHOME}"
#
# Import the PGP key and set its trust level to 5.
#
gpg --yes --batch --pinentry loopback --import "${PGP_PRIV_KEY}"
printf "5\ny\n" \
  | gpg --command-fd 0 --expert --edit-key "${PGP_KEY_ID}" trust
pass init "${PGP_KEY_ID}"
printf "password\nUsername: user\nTestCommand: echo\n%s" \
  "_MACRO: @TestCommand space @Username space @PASSWORD Return" \
  | pass insert -m macroFile
pass generate -f onlyPassword
#
# Copy Extension.
#
# Were the extension to be copied with the same name, this script would ignore
# it in every system that had it globally installed.
#
hash_name="$(sha1sum xmenu.bash)"
hash_name="xmenu_$(date '+%F')_${hash_name:0:13}.bash"
install -m 0700 xmenu.bash "${PASSWORD_STORE_EXTENSIONS_DIR}/${hash_name}"
pass "${hash_name%.bash}" "${@}"
