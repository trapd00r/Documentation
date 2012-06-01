#!/usr/bin/make
# Copyright (c) 2010-2011
# Frank Terbeck <ft@bewatermyfriend.org>, All rights reserved.
# Terms for redistribution and use can be found in `LICENCE'.

DOT_DEWI_DIR = ../.dewi
include $(DOT_DEWI_DIR)/config.mk
include $(DOT_DEWI_DIR)/lib/s_actions.mk

all:
	@$(CHILD_HELP)

archive:
	@$(ARCHIVES)

deploy:
	@$(DEPLOY_SUBDIR)

tar:
	@$(ARCHIVE_TAR)

tar-gz:
	@$(ARCHIVE_TAR_GZ)

tar-bz2:
	@$(ARCHIVE_TAR_BZ2)

withdraw:
	@$(WITHDRAW_SUBDIR)

update:
	@cp ../.dewi/lib/child.mk Makefile

-include local_dewi.mk
.PHONY: all deploy withdraw
