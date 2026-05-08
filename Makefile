DOTFILES_DIR := $(CURDIR)
TARGET       := $(HOME)
PACKAGES     := $(patsubst %/,%,$(wildcard */))

.PHONY: help list install uninstall restow adopt

help:
	@echo "Discovered packages: $(PACKAGES)"
	@echo
	@echo "Targets:"
	@echo "  make install              Symlink all packages into \$$HOME"
	@echo "  make uninstall            Remove all symlinks"
	@echo "  make restow               Recreate all symlinks"
	@echo "  make list                 List discovered packages"
	@echo "  make install-<pkg>        Stow a single package"
	@echo "  make uninstall-<pkg>      Unstow a single package"
	@echo "  make restow-<pkg>         Restow a single package"
	@echo "  make adopt PKG=<pkg>      Pull existing \$$HOME files into <pkg>"

list:
	@printf '%s\n' $(PACKAGES)

install:   $(addprefix install-,$(PACKAGES))
uninstall: $(addprefix uninstall-,$(PACKAGES))
restow:    $(addprefix restow-,$(PACKAGES))

install-%:
	stow --dir=$(DOTFILES_DIR) --target=$(TARGET) $*

uninstall-%:
	stow --dir=$(DOTFILES_DIR) --target=$(TARGET) --delete $*

restow-%:
	stow --dir=$(DOTFILES_DIR) --target=$(TARGET) --restow $*

adopt:
	@test -n "$(PKG)" || { echo "Usage: make adopt PKG=<package>"; exit 1; }
	stow --dir=$(DOTFILES_DIR) --target=$(TARGET) --adopt $(PKG)
