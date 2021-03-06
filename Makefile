PREFIX ?= /usr
EXTENSIONS_DIR ?= lib/password-store/extensions
DESTDIR ?=
SCRIPT := xmenu.bash
TEST_DIR := test_env
TEST_SCRIPT_DIR := $(TEST_DIR)/scripts
TEST_SOURCE_FILE := $(TEST_SCRIPT_DIR)/source.bash
TEST_SCRIPTS := $(TEST_SCRIPT_DIR)/check_macros.bash

install:
	install -d $(DESTDIR)$(PREFIX)/$(EXTENSIONS_DIR) 
	install -m 0755 $(SCRIPT) $(DESTDIR)$(PREFIX)/$(EXTENSIONS_DIR)

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/$(EXTENSIONS_DIR)/$(SCRIPT)

test: $(TEST_SCRIPTS)
	@for f in $^; do bash "$${f}" $(TEST_SOURCE_FILE); done

test-clean:
	rm -rf $(TEST_DIR)/gnupg $(TEST_DIR)/password-store

.PHONY: install uninstall test test-clean
