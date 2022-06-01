PREFIX ?= /usr/lib/password-store/extensions
DESTDIR ?=
EXTENSION = xmenu.bash

install:
	@install -vm 0755 $(EXTENSION) $(DESTDIR)$(PREFIX)/

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/$(EXTENSION)

.PHONY: install uninstall
