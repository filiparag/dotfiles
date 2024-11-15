MAKEFLAGS 	+= --silent
PREFIX		?= /
DEFAULT_USER	:= filiparag
DEFAULT_NAME	:= Filip Parag
DEFAULT_EMAIL	:= filip@parag.rs
WORKDIR		:= $(shell mktemp -d -t 'dotfiles-XXXXX')
WORKFILE	:= $(shell sudo mktemp -t 'dotfiles-XXXXX.tar')
SRCDIR		:= $(shell realpath ./src/)
MAKEFILE	:= $(shell realpath ./Makefile)

.PHONY: dependencies optional-dependencies symlink

copy: .bootstrap .type-copy .configure .prepare-copy .rename-firefox-profile .rename-copy .save-config .chown .package .install .cleanup .docs .post-install .post-install-optional
symlink: .bootstrap .type-symlink .configure .prepare-symlink .rename-firefox-profile .rename-symlink .save-config .chown .package .install .cleanup .docs .post-install .post-install-optional

.reload-copy: .prepare-copy .rename-firefox-profile .rename-copy .chown .package .install .cleanup .docs .post-install .post-install-optional
.reload-symlink: .prepare-symlink .rename-firefox-profile .rename-home .chown .package .install .cleanup .docs .post-install .post-install-optional

.type-copy:
	$(eval DOTFILES_TYPE=copy)

.type-symlink:
	$(eval DOTFILES_TYPE=symlink)

.bootstrap:
	sudo pacman -Sy --needed git dialog coreutils findutils pciutils
	command -v paru &> /dev/null || git clone https://aur.archlinux.org/paru-bin.git ${WORKDIR}/paru
	cd ${WORKDIR}/paru &> /dev/null && makepkg --needed -si && rm -rf ${WORKDIR}/paru || true

.configure:
	$(eval USERNAME=$(shell dialog --title 'Configuration' --inputbox "Username" 8 30 "${USER}" --output-fd 1))
	$(eval GROUP=$(shell dialog --title 'Configuration' --inputbox "User group" 8 30 "$(shell id -gn ${USERNAME})" --output-fd 1))
	$(eval HOMEDIR=$(shell dialog --title 'Configuration' --inputbox "Home directory" 8 30 "$(shell echo ~${USERNAME})" --output-fd 1))
	$(eval USER_NAME=$(shell dialog --title 'Configuration' --inputbox "Full name" 8 30 "${DEFAULT_NAME}" --output-fd 1))
	$(eval USER_EMAIL=$(shell dialog --title 'Configuration' --inputbox "Email" 8 30 "${DEFAULT_EMAIL}" --output-fd 1))

dependencies: .bootstrap
	if ! grep -q 'filiparag' /etc/pacman.conf; then \
		dialog --title 'Package installation' --yesno 'Use build server for AUR packages' 5 40 && \
		printf "[filiparag]\nSigLevel = Optional TrustAll\nServer = https://pkg.filiparag.com/archlinux/\n" | sudo tee -a /etc/pacman.conf || \
		true; \
	fi
	paru -Syu
	paru -S --needed - < pkglist.required.txt
	paru -S qt5-styleplugins qt6gtk2

optional-dependencies: .bootstrap
	$(eval OPT_DEPS_CMD=$(shell awk -F'\t' ' \
	BEGIN { \
		printf("dialog --title \"Optional dependencies\" --checklist \"Selection of apps not required for basic functionality\"  0 0 0 "); \
	} \
	{ \
		name = $$1; \
		$$1 = ""; \
		printf("%s \"%s\" on ", name, $$0); \
	} \
	END { \
		printf(" --output-fd 1\n"); \
	}' pkglist.optional.txt))
	$(eval OPT_DEPS=$(shell ${OPT_DEPS_CMD}))
	paru -S --needed ${OPT_DEPS}

.prepare-copy:
	cp -Rpd ${SRCDIR}/* ${WORKDIR}/

.prepare-symlink: .prepare-copy
	find ${WORKDIR} -not -type d -exec rm -f {} \;
	cat dirlist.txt | xargs -I{} rm -rf ${WORKDIR}/{}
	cat dirlist.txt | xargs -I{} ln -s ${SRCDIR}/{} ${WORKDIR}/{}
	awk 'BEGIN { printf("cd ${SRCDIR} && find * \\( -type f -o -type l \\)") } { printf(" -not -path \"%s/*\" ", $$0) } END { print "-exec ln -s ${SRCDIR}/{} ${WORKDIR}/{} \\;" }' dirlist.txt > ${WORKDIR}/symlink.sh
	sh ${WORKDIR}/symlink.sh && rm -f ${WORKDIR}/symlink.sh

.rename-copy:
	find ${WORKDIR} -type f -not -name 'pacman.conf' -exec sed -i 's|${DEFAULT_USER}|${USERNAME}|g' {} \;
	find ${WORKDIR} -type f -exec sed -i 's|${DEFAULT_NAME}|${USER_NAME}|g' {} \;
	find ${WORKDIR} -type f -exec sed -i 's|${DEFAULT_EMAIL}|${USER_EMAIL}|g' {} \;
	[ '${DEFAULT_EMAIL}' != '${USER_EMAIL}' ] && sed -i '/signingkey/d' ${WORKDIR}/HOME/.gitconfig || true
	dirname ${WORKDIR}/${HOMEDIR} | xargs mkdir -p
	mv ${WORKDIR}/HOME ${WORKDIR}/${HOMEDIR}

.rename-symlink:
	sed -i 's/^DEFAULT_USER.*/DEFAULT_USER	:= ${USERNAME}/' ${MAKEFILE}
	sed -i 's/^DEFAULT_NAME.*/DEFAULT_NAME	:= ${USER_NAME}/' ${MAKEFILE}
	sed -i 's/^DEFAULT_EMAIL.*/DEFAULT_EMAIL	:= ${USER_EMAIL}/' ${MAKEFILE}
	find ${SRCDIR} -type f -not -name 'pacman.conf' -exec sed -i 's|${DEFAULT_USER}|${USERNAME}|g' {} \;
	find ${SRCDIR} -type f -exec sed -i 's|${DEFAULT_NAME}|${USER_NAME}|g' {} \;
	find ${SRCDIR} -type f -exec sed -i 's|${DEFAULT_EMAIL}|${USER_EMAIL}|g' {} \;
	[ '${DEFAULT_EMAIL}' != '${USER_EMAIL}' ] && sed -i '/signingkey/d' ${SRCDIR}/HOME/.gitconfig || true
	dirname ${WORKDIR}/${HOMEDIR} | xargs mkdir -p
	mv ${WORKDIR}/HOME ${WORKDIR}/${HOMEDIR}

.rename-firefox-profile:
	if [ -f ${HOMEDIR}/.mozilla/firefox/profiles.ini ]; then \
		FIREFOX_PROFILE="$$(awk -F '=' '$$1=="Default"{if(!p){print $$2;p=1}}END{if(!p)print "dotfiles.default"}' ${HOMEDIR}/.mozilla/firefox/profiles.ini)"; \
		mv ${WORKDIR}/HOME/.mozilla/firefox/profile.default "${WORKDIR}/HOME/.mozilla/firefox/$$FIREFOX_PROFILE"; \
	fi

.rename-home:
	dirname ${WORKDIR}/${HOMEDIR} | xargs mkdir -p
	mv ${WORKDIR}/HOME ${WORKDIR}/${HOMEDIR}

.save-config:
	mkdir -p ${WORKDIR}/${HOMEDIR}/.config
	echo 'export DOTFILES_TYPE="${DOTFILES_TYPE}"' > ${WORKDIR}/${HOMEDIR}/.config/dotfiles.ini
	echo 'export USERNAME="${USERNAME}"' >> ${WORKDIR}/${HOMEDIR}/.config/dotfiles.ini
	echo 'export GROUP="${GROUP}"' >> ${WORKDIR}/${HOMEDIR}/.config/dotfiles.ini
	echo 'export HOMEDIR="${HOMEDIR}"' >> ${WORKDIR}/${HOMEDIR}/.config/dotfiles.ini
	echo 'export USER_NAME="${USER_NAME}"' >> ${WORKDIR}/${HOMEDIR}/.config/dotfiles.ini
	echo 'export USER_EMAIL="${USER_EMAIL}"' >> ${WORKDIR}/${HOMEDIR}/.config/dotfiles.ini

.chown:
	sudo -E find ${WORKDIR} -mindepth 1 -not -path '${WORKDIR}/${HOMEDIR}*' -exec chown root:root {} \;
	sudo -E find ${WORKDIR}/${HOMEDIR} -exec chown ${USERNAME}:${GROUP} {} \;

.package:
	sudo -E tar -cf ${WORKFILE} -C ${WORKDIR} .

.install:
	sudo -E mkdir -p ${PREFIX}
	sudo -E tar -xf ${WORKFILE} -C ${PREFIX}
	sudo -E chmod 0755 ${PREFIX}
	sudo -E chown root:root ${PREFIX}

.cleanup:
	lspci | grep -qi 'VGA.*Intel' || sudo rm -f ${PREFIX}/etc/X11/xorg.conf.d/20-intel.conf
	lspci | grep -qi 'VGA.*AMD' || sudo rm -f ${PREFIX}/etc/X11/xorg.conf.d/20-amdgpu.conf

.docs:
	sudo mkdir -p /usr/share/doc/dotfiles
	cat "${SRCDIR}/HOME/.config/sxhkd/sxhkdrc" | awk \
	'BEGIN { \
		print "# Keyboard shortcuts\n" \
	} \
	NR > 1 { \
		if ($$0 ~ /^## /) { \
			gsub(/^## */,"",$$0); printf("\n## %s\n\n",$$0) \
		} else if ($$0 ~ /^# /) { \
			gsub(/^# */,"",$$0); printf("%s ",$$0); c=1 \
		} else if (c==1) { \
			printf("`%s`\n\n", $$0); c=0 \
		} \
	}' | sudo tee /usr/share/doc/dotfiles/shortcuts.md 1>/dev/null
	cp /usr/share/doc/dotfiles/shortcuts.md ${SRCDIR}/../SHORTCUTS.md
	cat "${SRCDIR}/HOME/.config/sxhkd/sxhkdrc" | awk \
	'BEGIN { \
		first = 1; \
		printf("<html>\n<body style=\"font-family: sans-serif\">\n"); \
		printf("<h1>Dotfiles manual</h1>\n"); \
		printf("<h2>Keyboard shortcuts</h2>\n"); \
	} \
	NR > 1 { \
		if ($$0 ~ /^## /) { \
			if (first) { \
				first = 0; \
			} else { \
				printf("</ul>\n"); \
			} \
			gsub(/^## */,"",$$0); printf("<h3>%s</h3>\n<ul>\n",$$0) \
		} else if ($$0 ~ /^# /) { \
			gsub(/^# */,"",$$0); printf("\t <li>%s ",$$0); c=1 \
		} else if (c==1) { \
			printf("<code>%s</code></li>\n", $$0); c=0 \
		} \
	} \
	END { \
		print "</body>\n</html>\n" \
	}' | sudo tee /usr/share/doc/dotfiles/manual.html 1>/dev/null

.post-install: .post-install-system .post-install-services .post-install-firewall .post-install-user .post-install-apps

.post-install-system:
	sudo locale-gen

.post-install-services:
	sudo systemctl daemon-reload
	sudo systemctl enable "wmrc-suspend@${USERNAME}"
	sudo systemctl enable "wmrc-resume@${USERNAME}"
	sudo systemctl enable --now sshd
	sudo systemctl enable --now cronie
	sudo systemctl enable --now NetworkManager
	sudo systemctl enable --now avahi-daemon
	sudo systemctl enable --now systemd-resolved
	sudo systemctl enable --now systemd-timesyncd
	sudo systemctl enable --now ufw

.post-install-firewall:
	sudo ufw default deny incoming
	sudo ufw default allow outgoing
	sudo ufw allow ssh
	sudo ufw enable

.post-install-user:
	sudo chsh -s /usr/bin/fish "${USERNAME}"
	sudo usermod -aG input,kvm,optical,rfkill,uucp "${USERNAME}"
	gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

.post-install-apps:
	test -e /usr/bin/vi || sudo ln -s /usr/bin/vim /usr/bin/vi
	test -e /usr/bin/firefox || sudo ln -s /usr/bin/firefox-developer-edition /usr/bin/firefox

.post-install-optional:
	if command -v syncthing &>/dev/null; then \
		sudo systemctl enable --now "syncthing@${USERNAME}"; \
		sudo systemctl enable --now syncthing-resume; \
		sudo ufw allow syncthing; \
	else true; fi
	if command -v flatpak &>/dev/null; then \
		sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; \
		sudo flatpak override --env GTK_THEME=Adwaita:dark; \
	else true; fi
	if command -v kdeconnect-app &>/dev/null; then \
		sudo ufw allow 1714:1764/udp; \
		sudo ufw allow 1714:1764/tcp; \
	else true; fi
