ifeq ($(PACKAGE_SET),dom0)
RPM_SPEC_FILES := rpm_spec/xen-hvm-stubdom-linux.spec
endif

include $(ORIG_SRC)/Makefile.vars

INCLUDED_SOURCES = \
	qemu-$(QEMU_VERSION).tar.xz \
	linux-$(LINUX_VERSION).tar \
	busybox-$(BUSYBOX_VERSION).tar.bz2 \
	pulseaudio-$(PULSEAUDIO_VERSION).tar.xz \
	libusb-$(LIBUSB_VERSION).tar.bz2

ifneq ($(filter $(DISTRIBUTION), fedora centos),)
SOURCE_COPY_IN := $(INCLUDED_SOURCES)
endif

$(INCLUDED_SOURCES): PACKAGE=$@
$(INCLUDED_SOURCES):
	cp $(ORIG_SRC)/dl/$(PACKAGE) $(CHROOT_DIR)$(DIST_SRC)
# vim: set ft=make:
