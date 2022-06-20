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
MACROFILE="macroFile"
PASSWORD="pass1234"
USERNAME="username"

check_macro() {
  #
  # Run a macro with the action in ${1}.
  #

  pass "${HASH_NAME%.bash}" -atrue -A"${1}" &
  printf "Username: "
  {
    sleep 0.1
    xdotool type --clearmodifiers "${MACROFILE}"
    xdotool key --clearmodifiers Return
  } &
  read -r username
  printf "Password: "
  stty -echo
  read -r password
  stty echo
  printf "\n"

  if [[ "${username}" == "${USERNAME}" && "${password}" == "${PASSWORD}" ]]; then
    printf "%s Macro test successful\n" "${1}"
  else
    printf "%s Macro test FAILED!\n" "${1}"
    printf "Expected Values: Username: %s and Password: %s\n" \
      "${USERNAME}" "${PASSWORD}"
    printf "Actual Values: Username: %s and Password: %s\n" \
      "${username}" "${password}"
    exit 1
  fi
}
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
printf "%s\nUsername: %s\n%s" \
  "${PASSWORD}" "${USERNAME}" "_MACRO: @Username Return @PASSWORD Return" \
  | pass insert -m "${MACROFILE}"
#
# Copy Extension.
#
# Were the extension to be copied with the same name, this script would ignore
# it in every system that had it globally installed.
#
HASH_NAME="$(sha1sum xmenu.bash)"
HASH_NAME="xmenu_$(date '+%F')_${HASH_NAME:0:13}.bash"
install -m 0700 xmenu.bash "${PASSWORD_STORE_EXTENSIONS_DIR}/${HASH_NAME}"

#
# Check the generated key strokes
#
clear
check_macro "type"
check_macro "paste-term"
