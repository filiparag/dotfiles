ROOT?=		/
MKFILEREL!=	echo ${.MAKE.MAKEFILES} | sed 's/.* //'
MKFILEABS!=	readlink -f ${MKFILEREL} 2>/dev/null
MKFILEABS+=     $(shell readlink -f ${MAKEFILE_LIST})
MKWORKDIR!=	dirname ${MKFILEABS} 2>/dev/null
WORKDIR?=	${MKWORKDIR}
SRCDIR?=	${WORKDIR}/src
SCRIPTDIR?=	${WORKDIR}/scripts
PLISTDIR?=	${WORKDIR}/plist
FAKEROOT?=	${WORKDIR}/fakeroot
BACKUPROOT?=	${WORKDIR}/oldroot

default: clean soft

clean:
	@rm -rf ${FAKEROOT}

reset: clean
	@rm -rf ${BACKUPROOT} ${PLISTDIR}

hard: ${SRCDIR}
	@cp -af ${SRCDIR}/. ${FAKEROOT}
	@dirname ${HOME} | xargs -I{} mkdir -p ${FAKEROOT}{}
	@mv -f ${FAKEROOT}/HOME ${FAKEROOT}${HOME}

sym_%: ${SRCDIR} ${SCRIPTDIR} ${WORKDIR}/dirlist.txt
	@find ${SRCDIR} -type $$(echo $@ | cut -c5) | \
		sed 's:^${SRCDIR}::' | \
		awk -f ${SCRIPTDIR}/filter_$@.awk ${WORKDIR}/dirlist.txt - | \
		xargs -I{} echo '\
			path=$$(echo {} | sed "s:^/HOME/:${HOME}/:") && \
			mkdir -p ${FAKEROOT}$$(dirname $$path) && \
			ln -s ${SRCDIR}{} ${FAKEROOT}$$path' | \
		sh -

soft: sym_files sym_dirs

plist: ${FAKEROOT}
	@mkdir -p ${PLISTDIR}
	@find ${FAKEROOT} -type d -links 2 | sed 's:^${FAKEROOT}::' > ${PLISTDIR}/dirs
	@find ${FAKEROOT} -type f | sed 's:^${FAKEROOT}::' > ${PLISTDIR}/files
	@find ${FAKEROOT} -type l | sed 's:^${FAKEROOT}::' > ${PLISTDIR}/links

backup: ${ROOT} ${PLISTDIR}
	@mkdir -p ${BACKUPROOT}
	@cat ${PLISTDIR}/files ${PLISTDIR}/links | \
		xargs -I{} echo '\
			test -e ${ROOT}{} && \
			mkdir -p ${BACKUPROOT}$$(dirname {}) && \
			mv -f ${ROOT}{} ${BACKUPROOT}$$(dirname {}) || \
			true' | \
		sh -

restore: ${BACKUPROOT} ${ROOT}
	@(find ${BACKUPROOT} -type d -links 2; find ${BACKUPROOT} -type l,f) | \
		sed 's:^${BACKUPROOT}::' | \
		xargs -I{} echo '\
			test -e ${ROOT}{} && \
			rm -rf ${ROOT}{}; \
			uid=$$(ls -lad ${BACKUPROOT}{} | cut -d" " -f3) && \
			gid=$$(ls -lad ${BACKUPROOT}{} | cut -d" " -f4) && \
			install -o $$uid -g $$gid -d ${ROOT}$$(dirname {}) && \
			cp -a ${BACKUPROOT}{} ${ROOT}$$(dirname {})' | \
		sh -

install: ${FAKEROOT} plist backup
	@cp -a ${FAKEROOT}/. ${ROOT}

deinstall: ${ROOT} ${FAKEROOT} ${PLISTDIR}/dirs ${PLISTDIR}/files ${PLISTDIR}/links
	@cat ${PLISTDIR}/files | xargs -I{} rm -f ${ROOT}{}
	@cat ${PLISTDIR}/dirs | xargs -I{} rmdir -p ${ROOT}{}
