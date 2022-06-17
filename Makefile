PREFIX ?= /usr
EXTENSIONS_DIR ?= lib/password-store/extensions
DESTDIR ?=
SCRIPT = xmenu.bash
TEST_DIR = test_env
TEST_SCRIPT = $(TEST_DIR)/test.bash
TEST_SCRIPT_OPTS ?=

install:
	install -d $(DESTDIR)$(PREFIX)/$(EXTENSIONS_DIR) 
	install -m 0755 $(SCRIPT) $(DESTDIR)$(PREFIX)/$(EXTENSIONS_DIR)

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/$(EXTENSIONS_DIR)/$(SCRIPT)

test:
	bash $(TEST_SCRIPT) $(TEST_SCRIPT_OPTS)

test-clean:
	rm -rf $(TEST_DIR)/gnupg $(TEST_DIR)/password-store

.PHONY: install uninstall test test-clean
