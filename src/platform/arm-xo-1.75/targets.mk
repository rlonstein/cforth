# Makefile fragment for the final target application

SRC=$(TOPDIR)/src

# Target compiler definitions
ifneq "$(findstring arm,$(shell uname -m))" ""
include $(SRC)/cpu/host/compiler.mk
else
include $(SRC)/cpu/arm/compiler.mk
endif

include $(SRC)/common.mk
include $(SRC)/cforth/targets.mk
include $(SRC)/cforth/embed/targets.mk

DUMPFLAGS = --disassemble -z -x -s

VPATH += $(SRC)/cpu/arm $(SRC)/lib
VPATH += $(SRC)/platform/arm-xo-1.75
INCS += -I$(SRC)/platform/arm-xo-1.75

# Platform-specific object files for low-level startup and platform I/O

PLAT_OBJS = tstart.o

# Object files for the Forth system and application-specific extensions

# FORTH_OBJS = tmain.o embed.o textend.o  spiread.o consoleio.o
FORTH_OBJS = ttmain.o tembed.o textend.o  tspiread-simpler.o tconsoleio.o tinflate.o

SHIM_OBJS = tshimmain.o tspiread.o

# Recipe for linking the final image

# On XO-1.75, a masked-ROM loader copies CForth from SPI FLASH into SRAM
DICTIONARY=RAM

DICTSIZE=0xf000

RAMBASE  = 0xd1000000
IRQSTACKSIZE = 0x100
RAMTOP   = 0xd101f000
SHIMBASE = 0xd1018000

TSFLAGS += -DRAMTOP=${RAMTOP}
TSFLAGS += -DIRQSTACKSIZE=${IRQSTACKSIZE}

LIBGCC= -lgcc

version:
	git log -1 --format=format:"%H" >>$@ 2>/dev/null || echo UNKNOWN >>$@
	pwd
	echo VPATH = ${VPATH}

cforth.elf: version $(PLAT_OBJS) $(FORTH_OBJS)
	@echo 'const char version[] = "'`cat version`'" ;' >date.c
	@echo 'const char build_date[] = "'`date --utc +%F\ %R`'" ;' >>date.c
	@$(TCC) -c date.c
	@echo Linking $@ ... 
	@$(TLD) -N  -o $@  $(TLFLAGS) -Ttext $(RAMBASE) \
	    $(PLAT_OBJS) $(FORTH_OBJS) date.o \
	    $(LIBDIRS) $(LIBGCC)
	@$(TOBJDUMP) $(DUMPFLAGS) $@ >$(@:.elf=.dump)
	@nm -n $@ >$(@:.elf=.nm)

shim.elf: $(PLAT_OBJS) $(SHIM_OBJS)
	@echo Linking $@ ... 
	@$(TLD) -N  -o $@  $(TLFLAGS) -Ttext $(SHIMBASE) \
	    $(PLAT_OBJS) $(SHIM_OBJS) \
	    $(LIBDIRS) $(LIBGCC)
	@$(TOBJDUMP) $(DUMPFLAGS) $@ >$(@:.elf=.dump)
	@nm -n $@ >$(@:.elf=.nm)


# This rule extracts the executable bits from an ELF file, yielding raw binary.

%.img: %.elf
	@$(TOBJCOPY) -O binary $< $@
	@date  "+%F %H:%M" >>$@
	@ls -l $@

EXTRA_CLEAN += *.elf *.dump *.nm *.img date.c $(FORTH_OBJS) $(PLAT_OBJS) $(SHIM_OBJS) date.o version

