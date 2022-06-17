PREFIX ?= /usr
EXTENSIONS_DIR ?= /lib/password-store/extensions
DESTDIR ?=
SCRIPT = xmenu.bash
TEST_SCRIPT = test_env/test.bash
TEST_SCRIPT_OPTS ?=

install:
	@install -vd $(DESTDIR)$(PREFIX)/$(EXTENSIONS_DIR) 
	@install -vm 0755 $(SCRIPT) $(DESTDIR)$(PREFIX)/$(EXTENSIONS_DIR)

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/$(EXTENSION)

test:
	bash $(TEST_SCRIPT) $(TEST_SCRIPT_OPTS)

.PHONY: install uninstall test
