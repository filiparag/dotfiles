SRCDIR		?=	./src
WORKDIR		?=	./workdir
USER 		?=	filiparag
HOME		?=	/home/${USER}
PREFIX		?=	/
DATETIME 	:= 	$(shell date +%Y-%m-%d_%H-%M-%S)
SRCDIRABS	=	$(shell realpath ${SRCDIR})

.PHONY: all clean backup package symlink install

all: package

${WORKDIR}/.targets/workdir:
	@mkdir -p ${WORKDIR} \
		${WORKDIR}/.fakeroot ${WORKDIR}/.backups \
		${WORKDIR}/.list ${WORKDIR}/.targets
	@touch ${WORKDIR}/.list/files.txt ${WORKDIR}/.list/dirs.txt
	@echo '**' > ${WORKDIR}/.gitignore
	@touch ${WORKDIR}/.targets/workdir

${WORKDIR}/.targets/prepare: ${WORKDIR}/.targets/workdir
	@cp -f ${SRCDIR}/../dirlist.txt ${WORKDIR}/.list/dirs.txt
	@find ${SRCDIR} -not -type d > ${WORKDIR}/.list/files.txt
	@sed -i "s:^${SRCDIR}::" \
	 	${WORKDIR}/.list/dirs.txt ${WORKDIR}/.list/files.txt
	@grep -vF -f ${WORKDIR}/.list/dirs.txt \
		${WORKDIR}/.list/files.txt > ${WORKDIR}/.files.txt
	@mv -f ${WORKDIR}/.files.txt ${WORKDIR}/.list/files.txt
	@cp ${WORKDIR}/.list/files.txt ${WORKDIR}/.list/files.raw.txt
	@cp ${WORKDIR}/.list/dirs.txt ${WORKDIR}/.list/dirs.raw.txt
	@sed -i "s:^/HOME:${HOME}:" \
		${WORKDIR}/.list/dirs.raw.txt ${WORKDIR}/.list/files.raw.txt
	@touch ${WORKDIR}/.targets/prepare

clean:
	@rm -rf ${WORKDIR}/.fakeroot ${WORKDIR}/.list \
		${WORKDIR}/.targets ${WORKDIR}/dotfiles.tar.xz

backup: ${WORKDIR}/.targets/prepare
	@mkdir -p ${WORKDIR}/.backup
	@cat ${WORKDIR}/.list/files.raw.txt | \
		xargs -I{} echo \
		'mkdir -p ${WORKDIR}/.backup/$$(dirname {});' | sh -
	@cat ${WORKDIR}/.list/dirs.raw.txt ${WORKDIR}/.list/files.raw.txt | \
		xargs -I{} cp -frp {} ${WORKDIR}/.backup/{}
	@tar -C ${WORKDIR}/.backup \
		-cJf ${WORKDIR}/.backups/${DATETIME}.tar.xz .
	@ln -f ${WORKDIR}/.backups/${DATETIME}.tar.xz ${WORKDIR}/backup.tar.gz
	@rm -rf ${WORKDIR}/.backup

${WORKDIR}/.targets/fakeroot_dirs: ${WORKDIR}/.targets/prepare
	@cat ${WORKDIR}/.list/files.txt | \
		xargs -I{} echo \
		'mkdir -p ${WORKDIR}/.fakeroot/$$(dirname {});' | sh -
	@touch ${WORKDIR}/.targets/fakeroot_dirs

${WORKDIR}/.targets/fakeroot_home: ${WORKDIR}/.targets/prepare
	@mkdir -p ${WORKDIR}/.fakeroot/${HOME}
	@find ${WORKDIR}/.fakeroot/HOME -maxdepth 1 -mindepth 1 \
		-exec mv -f {} ${WORKDIR}/.fakeroot/${HOME} \;
	@rm -rf ${WORKDIR}/.fakeroot/HOME
	@touch ${WORKDIR}/.targets/fakeroot_home

${WORKDIR}/.targets/src_copy_hard: ${WORKDIR}/.targets/fakeroot_dirs
	@cat ${WORKDIR}/.list/dirs.txt ${WORKDIR}/.list/files.txt | \
		xargs -I{} cp -frp ${SRCDIR}/{} ${WORKDIR}/.fakeroot/{}
	@touch ${WORKDIR}/.targets/src_copy_hard ${WORKDIR}/.targets/src_copy

${WORKDIR}/.targets/src_copy_soft: ${WORKDIR}/.targets/fakeroot_dirs
	@cat ${WORKDIR}/.list/dirs.txt ${WORKDIR}/.list/files.txt | \
		xargs -I{} ln -sf ${SRCDIRABS}{} ${WORKDIR}/.fakeroot/{}
	@touch ${WORKDIR}/.targets/src_copy_soft ${WORKDIR}/.targets/src_copy
	
${WORKDIR}/.targets/hard: ${WORKDIR}/.targets/src_copy_hard ${WORKDIR}/.targets/fakeroot_home
	@touch ${WORKDIR}/.targets/src_copy

${WORKDIR}/.targets/soft: ${WORKDIR}/.targets/src_copy_soft ${WORKDIR}/.targets/fakeroot_home
	@touch ${WORKDIR}/.targets/src_copy

${WORKDIR}/.targets/package: ${WORKDIR}/.targets/src_copy
	@tar -C ${WORKDIR}/.fakeroot \
		-cJf ${WORKDIR}/dotfiles.tar.xz .
	@touch ${WORKDIR}/.targets/package

symlink: ${WORKDIR}/.targets/soft ${WORKDIR}/.targets/package

${WORKDIR}/dotfiles.tar.xz: ${WORKDIR}/.targets/src_copy_hard ${WORKDIR}/.targets/package

package: ${WORKDIR}/dotfiles.tar.xz
	@echo 'Package location: ${WORKDIR}/dotfiles.tar.xz'

install: ${WORKDIR}/dotfiles.tar.xz backup
	@tar -C ${PREFIX} -xf ${WORKDIR}/dotfiles.tar.xz
