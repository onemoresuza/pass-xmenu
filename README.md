# pass-xmenu

## Description
`pass-xmenu` is a pass extension that provides an xmenu for entry selection and
the possibility to execute macros to autofill empty fields.

## Dependencies
* [pass](https://www.passwordstore.org/)
* [xdotool](https://github.com/jordansissel/xdotool)

## Installation
### System-wide

```
# make install
```

### User specific
The variable `PASSWORD_STORE_ENABLE_EXTENSIONS` must be set to `true`.

```
$ make install \
	PREFIX="${PASSWORD_STORE_EXTENSIONS_DIR:-${PASSWORD_STORE_DIR:-"${HOME}/.password-store/.extensions"}}"
```

**Note**: If `PASSWORD_STORE_SIGNING_KEY` is set, remember to run:

```
$ gpg --default-key=<.gpg-id-key> --detach-sign xmenu.bash
```
and move the `.sig` file to the same directory as `xmenu.bash`.

## Macros
Macros are fields that start with `_MACRO` that contain:

1. **Actions**: `paste`, `paste-term` and `type`; are prefixed with a '%', *e. g.*, `%type`.
2. **Fields**: are any of the fields present in the file prefixed with a '@'; the
  password one may be accessed with the special field `@PASSWORD`. Absent fields
  are ignored.
3. **Key Presses**: any other string; they must be compatible with `xdotool
   key`.

```
aRandomPassword
Username: user
anyOtherField: fieldValue
_MACRO: %prompt @Username Tab @PASSWORD Return
```

In this example, if the user chooses to autofill, `pass-xmenu` will firstly
prompt the user to pick an action, then execute that action with the field
`Username`, press `Tab`, execute the same action with the special field
`PASSWORD`, and finally press `Return`.

## Environment Variables
1. `PASSWORD_STORE_XMENU`: Sets the xmenu to be used (default: `dmenu`);
2. `PASSWORD_STORE_XMENU_FLAGS`: The flags to be used when calling the xmenu
   (default: `""`);
3. `PASSWORD_STORE_XMENU_PROMPT_FLAG`: The xmenu prompt flag (default: `-p`);
4. `PASSWORD_STORE_XMENU_DEFAULT_ACTION`: the default action to execute
   (default: `type`).
