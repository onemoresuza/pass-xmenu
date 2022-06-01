PREFIX ?= /usr/lib/password-store/extensions
DESTDIR ?=
EXTENSION = xmenu.bash

install:
	cp $(EXTENSION) $(DESTDIR)/$(PREFIX)/
	chmod 755 $(DESTDIR)/$(PREFIX)/$(EXTENSION)

uninstall:
	rm -f $(DESTDIR)/$(PREFIX)/$(EXTENSION)

.PHONY: install uninstall
