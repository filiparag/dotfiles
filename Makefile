PREFIX			?= /
DEFAULT_USER	:= filiparag
DEFAULT_NAME	:= Filip Parag
DEFAULT_EMAIL	:= filip@parag.rs
WORKDIR			:= $(shell mktemp -d -t 'dotfiles-XXXXX')
WORKFILE		:= $(shell sudo mktemp -t 'dotfiles-XXXXX.tar')
SRCDIR			:= $(shell realpath ./src/)

.PHONY: dependencies symlink

copy: .bootstrap .configure .prepare-copy .rename .chown .package .install .cleanup .docs .post-install
	@echo 'export DOTFILES_TYPE=copy' >> ${HOMEDIR}/.config/dotfiles.ini

symlink: .bootstrap .configure .prepare-symlink .rename .chown .package .install .cleanup .docs .post-install
	@echo 'export DOTFILES_TYPE=symlink' >> ${HOMEDIR}/.config/dotfiles.ini

.reload-copy: .prepare-copy .rename .chown .package .install .cleanup .docs .post-install
.reload-symlink: .prepare-symlink .rename-home .chown .package .install .cleanup .docs .post-install

.bootstrap:
	@sudo pacman -Sy --needed git dialog coreutils findutils pciutils
	@command -v paru &> /dev/null || git clone https://aur.archlinux.org/paru-bin.git ${WORKDIR}/paru
	@cd ${WORKDIR}/paru &> /dev/null && makepkg --needed -si && rm -rf ${WORKDIR}/paru || true

.configure:
	@$(eval USERNAME=$(shell dialog --title 'Configuration' --inputbox "Username" 8 30 "${USER}" --output-fd 1))
	@$(eval GROUP=$(shell dialog --title 'Configuration' --inputbox "User group" 8 30 "$(shell id -gn ${USERNAME})" --output-fd 1))
	@$(eval HOMEDIR=$(shell dialog --title 'Configuration' --inputbox "Home directory" 8 30 "$(shell echo ~${USERNAME})" --output-fd 1))
	@$(eval USER_NAME=$(shell dialog --title 'Configuration' --inputbox "Full name" 8 30 "${DEFAULT_NAME}" --output-fd 1))
	@$(eval USER_EMAIL=$(shell dialog --title 'Configuration' --inputbox "Email" 8 30 "${DEFAULT_EMAIL}" --output-fd 1))
	@mkdir -p ${HOMEDIR}/.config
	@echo 'export USERNAME="${USERNAME}"' > ${HOMEDIR}/.config/dotfiles.ini
	@echo 'export GROUP="${GROUP}"' >> ${HOMEDIR}/.config/dotfiles.ini
	@echo 'export HOMEDIR="${HOMEDIR}"' >> ${HOMEDIR}/.config/dotfiles.ini
	@echo 'export USER_NAME="${USER_NAME}"' >> ${HOMEDIR}/.config/dotfiles.ini
	@echo 'export USER_EMAIL="${USER_EMAIL}"' >> ${HOMEDIR}/.config/dotfiles.ini

dependencies: .bootstrap
	@if ! grep -q 'filiparag' /etc/pacman.conf; then \
		dialog --title 'Package installation' --yesno 'Use build server for AUR packages' 5 40 && \
		printf "[filiparag]\nSigLevel = Optional TrustAll\nServer = https://pkg.filiparag.com/archlinux/\n" | sudo tee -a /etc/pacman.conf || \
		true; \
	fi
	@paru -Sy --needed - < pkglist.txt

.prepare-symlink: .prepare-copy
	@find ${WORKDIR} -not -type d -exec rm -f {} \;
	@cat dirlist.txt | xargs -I{} rm -rf ${WORKDIR}/{}
	@cat dirlist.txt | xargs -I{} ln -s ${SRCDIR}/{} ${WORKDIR}/{}
	@awk 'BEGIN { printf("cd ${SRCDIR} && find * \\( -type f -o -type l \\)") } { printf(" -not -path \"%s/*\" ", $$0) } END { print "-exec ln -s ${SRCDIR}/{} ${WORKDIR}/{} \\;" }' dirlist.txt > ${WORKDIR}/symlink.sh
	@sh ${WORKDIR}/symlink.sh && rm -f ${WORKDIR}/symlink.sh

.prepare-copy:
	@cp -Rpd ${SRCDIR}/* ${WORKDIR}/

.rename:
	@find ${WORKDIR} -type f -not -name 'pacman.conf' -exec sed -i 's|${DEFAULT_USER}|${USERNAME}|g' {} \;
	@find ${WORKDIR} -type f -exec sed -i 's|${DEFAULT_NAME}|${USER_NAME}|g' {} \;
	@find ${WORKDIR} -type f -exec sed -i 's|${DEFAULT_EMAIL}|${USER_EMAIL}|g' {} \;
	@[ '${DEFAULT_EMAIL}' != '${USER_EMAIL}' ] && sed -i '/signingkey/d' ${WORKDIR}/HOME/.gitconfig || true
	@dirname ${WORKDIR}/${HOMEDIR} | xargs mkdir -p
	@mv ${WORKDIR}/HOME ${WORKDIR}/${HOMEDIR}

.rename-home:
	@dirname ${WORKDIR}/${HOMEDIR} | xargs mkdir -p
	@mv ${WORKDIR}/HOME ${WORKDIR}/${HOMEDIR}

.chown:
	@sudo -E find ${WORKDIR} -mindepth 1 -not -path '${WORKDIR}/${HOMEDIR}*' -exec chown root:root {} \;
	@sudo -E find ${WORKDIR}/${HOMEDIR} -exec chown ${USERNAME}:${GROUP} {} \;

.package:
	@sudo -E tar -cf ${WORKFILE} -C ${WORKDIR} .

.install:
	@sudo -E mkdir -p ${PREFIX}
	@sudo -E tar -xf ${WORKFILE} -C ${PREFIX}
	@sudo -E chmod 0755 ${PREFIX}
	@sudo -E chown root:root ${PREFIX}

.cleanup:
	@lspci | grep -qi 'VGA.*Intel' || sudo rm -f ${PREFIX}/etc/X11/xorg.conf.d/20-intel.conf
	@lspci | grep -qi 'VGA.*AMD' || sudo rm -f ${PREFIX}/etc/X11/xorg.conf.d/20-amdgpu.conf

.docs:
	@sudo mkdir -p /usr/share/doc/dotfiles
	@cat "${SRCDIR}/HOME/.config/sxhkd/sxhkdrc" | awk \
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
	@cat "${SRCDIR}/HOME/.config/sxhkd/sxhkdrc" | awk \
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

.post-install:
	@sudo systemctl daemon-reload
	@sudo systemctl enable "resume@${USERNAME}"
	@sudo systemctl enable --now sshd
	@sudo systemctl enable --now cronie
	@sudo systemctl enable --now NetworkManager
	@sudo systemctl enable --now avahi-daemon
	@sudo systemctl enable --now "syncthing@${USERNAME}"
	@sudo systemctl enable --now syncthing-resume
	@sudo systemctl enable --now systemd-resolved
	@sudo systemctl enable --now systemd-timesyncd
	@sudo systemctl enable --now ufw
	@sudo ufw default deny incoming
	@sudo ufw default allow outgoing
	@sudo ufw allow ssh
	@sudo ufw allow syncthing
	@sudo ufw allow 1714:1764/udp
	@sudo ufw allow 1714:1764/tcp
	@sudo ufw enable
	@sudo chsh -s /usr/bin/fish "${USERNAME}"
	@sudo gpasswd -a "${USERNAME}" input
	@test -e /usr/bin/vi || sudo ln -s /usr/bin/vim /usr/bin/vi
	@test -e /usr/bin/firefox || sudo ln -s /usr/bin/firefox-developer-edition /usr/bin/firefox
	@sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
	@gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
