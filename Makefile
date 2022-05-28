.POSIX:
PREFIX ?= /usr/lib/password-store/extensions
EXTENSION = xmenu.bash

install:
	cp $(EXTENSION) $(PREFIX)/
	chmod 755 $(PREFIX)/$(EXTENSION)

uninstall:
	rm -f $(PREFIX)/$(EXTENSION)
