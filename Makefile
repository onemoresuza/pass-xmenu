PREFIX ?= /usr
EXTENSIONS_DIR ?= /lib/password-store/extensions
DESTDIR ?=
SCRIPT = xmenu.bash

install:
	@install -vd $(DESTDIR)$(PREFIX)/$(EXTENSIONS_DIR) 
	@install -vm 0755 $(SCRIPT) $(DESTDIR)$(PREFIX)/

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/$(EXTENSION)

.PHONY: install uninstall
