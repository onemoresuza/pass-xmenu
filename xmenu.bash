#!/usr/bin/env bash

# Shellcheck global directives:
#
# Use variables as printf's format string.
# shellcheck disable=SC2086
#
# Don't expand expressions in single quotes.
# shellcheck disable=SC2016
#

PROGNAME="pass xmenu"
XMENU="${PASSWORD_STORE_XMENU:-dmenu} ${PASSWORD_STORE_XMENU_FLAGS}"
XMENU_PROMPT_FLAG="${PASSWORD_STORE_XMENU_PROMPT_FLAG:-"-p"}"
ACTION="${PASSWORD_STORE_XMENU_DEFAULT_ACTION:-type}"

rperr() {
  #
  # Report an error to stderr.
  #
  fmtstr="${1}"
  shift
  if tty 1>/dev/null 2>&1; then
    printf "%s: ${fmtstr}\n" "${PROGNAME}" "${@}" 1>&2
  else
    fmtstr="$(printf "%s" "${fmtstr}" \
      | sed 's/\\033\[[[:digit:];[:upper:]]*m//g')"
    printf "Exit 1" \
      | ${XMENU} ${XMENU_PROMPT_FLAG} \
        "$(printf "%s: ${fmtstr}" "${PROGNAME}" "${@}")"
  fi
}

randstr() {
  #
  # Generate a random string.
  #
  tr -dc "${1}" </dev/urandom | dd count=1 bs="${1}" 2>/dev/null
}

#
# Option parsing.
#
lopts="autofill:,type,paste,paste-term,copy"
sopts="a:tpPc"
argv="$(getopt -l "${lopts}" -o "${sopts}" -- "${@}" 2>&1)" || {
  argv="${argv%[[:space:]]*}"
  argv="${argv%%[[:cntrl:]]*}"
  rperr "${argv#*[[:space:]]}"
  exit 1
}
eval set -- "${argv}"
autofill="prompt"
declare -a incmpopts
while true; do
  case "${1}" in
    "--autofill" | "-a")
      shift
      if [[ "${1}" =~ (true|prompt|false) ]]; then
        autofill="${1}"
      else
        rperr "\"%s\" is not a valid option for -a/--autofill." "${1}"
        exit 1
      fi
      ;;
    "--type" | "-t") 
      incmpopts+=("1")
      ACTION="type"
      if [[ "${#incmpopts[@]}" -gt 1 ]]; then
        rperr "-p/--paste, -P/--paste-term, -t/--type and -c/--copy are incompatible."
        exit 1
      fi
      ;;
    "--paste" | "-p") 
      incmpopts+=("1")
      ACTION="paste"
      if [[ "${#incmpopts[@]}" -gt 1 ]]; then
        rperr "-p/--paste, -P/--paste-term, -t/--type and -c/--copy are incompatible."
        exit 1
      fi
      ;;
    "--paste-term" | "-P") 
      incmpopts+=("1")
      ACTION="paste-term"
      if [[ "${#incmpopts[@]}" -gt 1 ]]; then
        rperr "-p/--paste, -P/--paste-term, -t/--type and -c/--copy are incompatible."
        exit 1
      fi
      ;;
    "--copy" | "-c") 
      incmpopts+=("1")
      ACTION="copy"
      if [[ "${#incmpopts[@]}" -gt 1 ]]; then
        rperr "-p/--paste, -P/--paste-term, -t/--type and -c/--copy are incompatible."
        exit 1
      fi
      ;;
    "--") shift; break;;
  esac
  shift
done

#
# Check ACTION.
#
[[ "${ACTION}" =~ (paste|paste-term|type|prompt|copy) ]] || {
  rperr "Valid actions are \"paste\", \"paste-term\","
  rperr "\"type\", \"propmt\" or \"copy\"."
  exit 1
}

#
# Prompt the user to pick a password.
#
passfile="$(
  find "${PREFIX}" \
    -type f \
    -name "*.gpg" \
    -exec sh -c '
      basename="${1#"${2}/"}"
      basename="${basename%.*}"
      printf "%s\n" "${basename}"' shell {} "${PREFIX}" \; \
    | ${XMENU} ${XMENU_PROMPT_FLAG} "Pick a password:"
)" || {
  rperr "No password picked."
  exit 1
}

#
# Store the file contents and macros and make sure they are filled with random
# chars at the given signals.
#
declare -a contents
declare -a macros
atexit() {
  for i in "${!contents[@]}"; do
    contents["${i}"]="$(randstr "[:print:]" "${#contents["${i}"]}")"
    contents["${i}"]="$(randstr "[:print:]" "$((RANDOM % 32 + 32))")"
    unset "contents[${i}]"
  done
  for i in "${!macros[@]}"; do
    macros["${i}"]="$(randstr "[:print:]" "${#macros["${i}"]}")"
    macros["${i}"]="$(randstr "[:print:]" "$((RANDOM % 32 + 32))")"
    unset "macros[${i}]"
  done
}
trap atexit EXIT INT

while IFS= read -r line; do
  if [ -z "${contents[0]}" ]; then
    contents+=("PASSWORD: ${line}")
  else
    case "${line}" in
      _MACRO*) macros+=("${line}");;
      *) contents+=("${line}");;
    esac
  fi
done <<EOF
$(${GPG} -d "${GPG_OPTS[@]}" "${PREFIX}/${passfile}.gpg")
EOF

#
# Autofill prompt.
#
[[ "${autofill}" == "prompt" && "${#macros[@]}" -gt 0 ]] && {
  autofill="$(
    printf "Yes\nNo\n" | ${XMENU} ${XMENU_PROMPT_FLAG} "Autofill?"
  )" || {
    rperr "No Option Picked."
    exit 1
  }
  case "${autofill}" in
    "Yes") autofill="true";;
    "No") autofill="false";;
  esac
}
pickdmacro=""
if [[ "${autofill}" == "true" && "${#macros[@]}" -gt 0 ]]; then
  if [[ "${#macros[@]}" -gt 1 ]]; then
    pickdmacro="$(
      for i in "${!macros[@]}"; do
        printf "%d: %s\n" "${i}" "${macros[${i}]%%:*}"
      done | ${XMENU} ${XMENU_PROMPT_FLAG} "Pick a Macro:"
    )" || {
      rperr "No Macro Picked."
      exit 1
    }
    pickdmacro="${macros[${pickdmacro%%:*}]#*:}"
  else
    pickdmacro="${macros[0]#*:}"
  fi
fi

#
# For autofill == false.
#
if [ -z "${pickdmacro}" ]; then
  #
  # Set action.
  #
  if [[ "${ACTION}" == "prompt" ]]; then
    pickdmacro="%$(
      printf "copy\npaste\npaste-term\ntype" \
        | ${XMENU} ${XMENU_PROMPT_FLAG} "Pick an Action:"
    )" || {
      rperr "No Action Picked."
      exit 1
    }
  else
    pickdmacro="%${ACTION}"
  fi
  #
  # Set field.
  #
  pickdmacro="${pickdmacro} @$(
    for field in "${contents[@]}"; do
      printf "%s\n" "${field%%:*}"
    done \
      | ${XMENU} ${XMENU_PROMPT_FLAG} "Pick a field"
  )" || {
    rperr "No field picked."
    exit 1
  }
fi

#
# Execute the macro.
#
for cmd in ${pickdmacro}; do
  if [[ "${cmd}" =~ ^%.* ]]; then
    case "${cmd#?}" in
      "prompt")
        ACTION="%$(
          printf "copy\npaste\npaste-term\ntype" \
            | ${XMENU} ${XMENU_PROMPT_FLAG} "Pick an Action:"
        )" || {
          rperr "No Action Picked."
          exit 1
        }
        ACTION="${ACTION#?}"
        ;;
      "wait")
        waitprompt="Press Return When the Next Page Loads"
        printf "Cotinue" \
          | ${XMENU} ${XMENU_PROMPT_FLAG} "${waitprompt}" 1>/dev/null 2>&1 || {
          rperr "Quit ${XMENU%%[[:space:]]*}"
          exit 1
        }
        ;;
      *) ACTION="${cmd#?}";;
    esac
  elif [[ "${cmd}" =~ ^@.* ]]; then
    #
    # If the default action is "prompt" and the macro does not contain an action
    # until now.
    #
    if [[ "${ACTION}" == "prompt" ]]; then
      ACTION="$(
        printf "copy\npaste\npaste-term\ntype" \
          | ${XMENU} ${XMENU_PROMPT_FLAG} "Pick an Action:"
      )" || {
        rperr "No Action Picked."
        exit 1
      }
    fi
    field="${cmd#?}"
    case "${ACTION}" in
      "copy")
        actioncmd='
          clip "${contents[${i}]#*:[[:space:]]}" "${passfile}"
        '
        ;;
      "paste")
        actioncmd='
          printf "%s" "${contents[${i}]#*:[[:space:]]}" | xclip -sel "${X_SELECTION}" -i
          xdotool key --clearmodifiers control+v
          xclip -sel "${X_SELECTION}" -i /dev/null
        '
        ;;
      "paste-term")
        actioncmd='
          printf "%s" "${contents[${i}]#*:[[:space:]]}" | xclip -sel "${X_SELECTION}" -i
          xdotool key --clearmodifiers control+shift+v
          xclip -sel "${X_SELECTION}" -i /dev/null
        '
        ;;
      "type")
        actioncmd='
          xdotool type --clearmodifiers "${contents[${i}]#*:[[:space:]]}"
        '
        ;;
    esac
    for i in "${!contents[@]}"; do
      case "${field}" in
        "${contents[${i}]%%:*}") eval "${actioncmd}"; break;;
      esac
    done
  else
    #
    # Some times when any of the paste actions are executed, the call to
    # `xdotool key` does not work. This call to sleep is a workaround to fix
    # it.
    #
    sleep 0.1
    [ -n "$(xdotool key --clearmodifiers "${cmd}" 2>&1)" ] && {
      rperr "Invalid key \"%s\"." "${cmd}"
      exit 1
    }
  fi
done
