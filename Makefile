.DEFAULT_GOAL = get-sources
.SECONDEXPANSION:

.PHONY: get-sources verify-sources clean clean-sources

SHELL := bash

include Makefile.vars

UNTRUSTED_SUFF := .UNTRUSTED

ifeq ($(FETCH_CMD),)
$(error "You can not run this Makefile without having FETCH_CMD defined")
endif

URLS := \
    https://download.qemu.org/qemu-$(QEMU_VERSION).tar.xz.sig \
    https://kernel.org/pub/linux/kernel/v$(firstword $(subst ., ,$(LINUX_VERSION))).x/linux-$(LINUX_VERSION).tar.sign \
    https://busybox.net/downloads/busybox-$(BUSYBOX_VERSION).tar.bz2.sig \
    https://www.freedesktop.org/software/pulseaudio/releases/pulseaudio-$(PULSEAUDIO_VERSION).tar.xz \
    https://github.com/libusb/libusb/releases/download/v$(LIBUSB_VERSION)/libusb-$(LIBUSB_VERSION).tar.bz2

ALL_URLS := $(patsubst %.sign,%,$(patsubst %.sig,%,$(URLS))) $(filter %.sig, $(URLS)) $(filter %.sign, $(URLS))
ALL_FILES_TMP := $(notdir $(ALL_URLS))

ifneq ($(DISTFILES_MIRROR),)
ALL_URLS := $(addprefix $(DISTFILES_MIRROR),$(ALL_FILES_TMP))
endif

ALL_FILES := $(addprefix dl/,$(ALL_FILES_TMP))

$(filter %.sig, $(ALL_FILES)) $(filter %.sign, $(ALL_FILES)): dl/%:
	@mkdir -p dl
	@$(FETCH_CMD) $@ $(filter %/$*,$(ALL_URLS))

keys/%.gpg: $$(sort $$(wildcard keys/$$*/*.asc))
	@cat $^ | gpg --dearmor >$@

dl/%: dl/%.sig keys/$$(firstword $$(subst -, ,$$*)).gpg
	@$(FETCH_CMD) $@$(UNTRUSTED_SUFF) $(filter %/$*,$(ALL_URLS))
	@gpgv --keyring $(word 2,$^) $< $@$(UNTRUSTED_SUFF) 2>/dev/null || \
		{ echo "Wrong signature on $@$(UNTRUSTED_SUFF)!"; exit 1; }
	@mv $@$(UNTRUSTED_SUFF) $@

dl/%: dl/%.sign keys/$$(firstword $$(subst -, ,$$*)).gpg
	@$(FETCH_CMD) $@.xz$(UNTRUSTED_SUFF) $(filter %/$*,$(ALL_URLS)).xz
	@if [ -f /usr/bin/qvm-run-vm ]; \
		then qvm-run-vm --dispvm 2>/dev/null xzcat <$@.xz$(UNTRUSTED_SUFF) > $@$(UNTRUSTED_SUFF); \
		else xzcat <$@.xz$(UNTRUSTED_SUFF) > $@$(UNTRUSTED_SUFF); fi
	@rm -f $@.xz$(UNTRUSTED_SUFF)
	@gpgv --keyring $(word 2,$^) $< $@$(UNTRUSTED_SUFF)|| \
		{ echo "Wrong signature on $@$(UNTRUSTED_SUFF)!"; exit 1; }
	@mv $@$(UNTRUSTED_SUFF) $@

dl/%: checksums/%.sha512
	@$(FETCH_CMD) $@$(UNTRUSTED_SUFF) $(filter %/$*,$(ALL_URLS))
	@sha512sum --status -c <(printf "$$(cat $<)  -\n") <$@$(UNTRUSTED_SUFF) || \
		{ echo "Wrong SHA512 checksum on $@$(UNTRUSTED_SUFF)!"; exit 1; }
	@mv $@$(UNTRUSTED_SUFF) $@

get-sources: $(ALL_FILES)
	git submodule update --init

verify-sources:
	@true

clean:
	$(MAKE) -f Makefile.stubdom clean

clean-sources:
	rm -rf dl
