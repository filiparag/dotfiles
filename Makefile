PREFIX			?= /
DEFAULT_USER	:= filiparag
DEFAULT_NAME	:= Filip Parag
DEFAULT_EMAIL	:= filip@parag.rs
WORKDIR			:= $(shell mktemp -d -t 'dotfiles-XXXXX')
WORKFILE		:= $(shell sudo mktemp -t 'dotfiles-XXXXX.tar')
SRCDIR			:= $(shell realpath ./src/)

.PHONY: symlink

copy: .bootstrap .configure .prepare-copy .rename .chown .package .install .cleanup .docs .post-install
symlink: .bootstrap .configure .prepare-symlink .rename .chown .package .install .cleanup .docs .post-install

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
	@awk 'BEGIN { printf("cd ${SRCDIR} && find * -type f") } { printf(" -not -path \"%s/*\" ", $$0) } END { print "-exec ln -s ${SRCDIR}/{} ${WORKDIR}/{} \\;" }' dirlist.txt > ${WORKDIR}/symlink.sh
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

.chown:
	@sudo -E find ${WORKDIR} -mindepth 1 -not -path '${WORKDIR}/${HOMEDIR}*' -exec chown root:root {} \;
	@sudo -E find ${WORKDIR}/${HOMEDIR} -exec chown ${USERNAME}:${GROUP} {} \;

.package:
	@sudo -E tar -cf ${WORKFILE} -C ${WORKDIR} .

.install:
	@sudo -E mkdir -p ${PREFIX}
	@sudo -E tar -xf ${WORKFILE} -C ${PREFIX}
	@sudo -E chown root:root ${PREFIX}
	@sudo -E chmod 0755 ${PREFIX}

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
	}' | sudo tee /usr/share/doc/dotfiles/shortcuts.md

.post-install:
	@sudo systemctl enable "sshd"
	@sudo systemctl enable "cronie"
	@sudo systemctl enable "NetworkManager"
	@sudo systemctl enable "suspend@${USERNAME}"
	@sudo systemctl enable "syncthing@${USERNAME}"
	@sudo systemctl enable "syncthing-resume"
	@sudo systemctl enable "systemd-resolved"
	@sudo systemctl enable "ufw"
	@sudo ufw default deny incoming
	@sudo ufw default allow outgoing
	@sudo ufw allow ssh
	@sudo ufw allow syncthing
	@sudo ufw enable
	@sudo chsh -s /usr/bin/fish "${USERNAME}"
