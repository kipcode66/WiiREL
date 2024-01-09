#---------------------------------------------------------------------------------
# Clear the implicit built in rules
#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------
ifeq ($(strip $(DEVKITPPC)),)
$(error "Please set DEVKITPPC in your environment. export DEVKITPPC=<path to>/devkitPPC")
endif

include $(DEVKITPPC)/wii_rules

# Format: YYYYMMDDHHmm + 2 char Game Region
BUILDID:='"$(shell date +'%Y%m%d%H%M')"'

# Version
_VERSION_MAJOR:=1
_VERSION_MINOR:=0
_VERSION_PATCH:=0
_VERSION:='"$(_VERSION_MAJOR).$(_VERSION_MINOR).$(_VERSION_PATCH)"'
# Variant: i.e. Public, NoLogic, Race, etc.
_VARIANT:=public

# This shows up in the memory card (manager) and can contain spaces
PROJECT_NAME := REL Example
# This will be the resulting .gci file - No spaces
OUTPUT_FILENAME := REL


# DON'T TOUCH UNLESS YOU KNOW WHAT YOU'RE DOING
LIBTP_REL := externals/libtp_rel

NANDPACK := python3 ../bin/nandpack.py

UNAME := $(shell uname)

ifeq ($(UNAME), Linux)
	ELF2REL := wine ../bin/elf2rel.exe
else
	ELF2REL := ../bin/elf2rel.exe
endif


ifeq ($(VERSION),)
all: us0 us2 jp eu
us0:
	@$(MAKE) --no-print-directory VERSION=us0
us2:
	@$(MAKE) --no-print-directory VERSION=us2
jp:
	@$(MAKE) --no-print-directory VERSION=jp
eu:
	@$(MAKE) --no-print-directory VERSION=eu

clean:
	@$(MAKE) --no-print-directory clean_target VERSION=us0
	@$(MAKE) --no-print-directory clean_target VERSION=us2
	@$(MAKE) --no-print-directory clean_target VERSION=jp
	@$(MAKE) --no-print-directory clean_target VERSION=eu

.PHONY: all clean us0 us2 jp eu
else

#---------------------------------------------------------------------------------
# TARGET is the name of the output
# BUILD is the directory where object files & intermediate files will be placed
# SOURCES is a list of directories containing source code
# INCLUDES is a list of directories containing extra header files
#---------------------------------------------------------------------------------
TARGET		:=	$(OUTPUT_FILENAME).$(VERSION)
BUILD		:=	build.$(VERSION)
SOURCES		:=	source $(wildcard source/*) $(LIBTP_REL)/source $(wildcard $(LIBTP_REL)/source/*)
DATA		:=	data
INCLUDES	:=	include $(LIBTP_REL)/include

#---------------------------------------------------------------------------------
# options for code generation
#---------------------------------------------------------------------------------

MACHDEP		= -mno-sdata -mrvl -DGEKKO -mcpu=750 -meabi -mhard-float

CFLAGS		= -nostdlib -ffunction-sections -fdata-sections -g -Oz -fvisibility=hidden -Wall -Werror -Wextra -Wno-address-of-packed-member -Wno-stringop-truncation -Wno-address-of-packed-member $(MACHDEP) $(INCLUDE) -D_PROJECT_NAME='"$(PROJECT_NAME)"' -D_VERSION_MAJOR='$(_VERSION_MAJOR)' -D_VERSION_MINOR='$(_VERSION_MINOR)' -D_VERSION_PATCH='$(_VERSION_PATCH)'  -D_VERSION='"$(_VERSION)"' -D_VARIANT='"$(_VARIANT)"' -DPLATFORM_WII=1
CXXFLAGS	= -fno-exceptions -fno-rtti -std=gnu++20 $(CFLAGS)

LDFLAGS		= -r -e _prolog -u _prolog -u _epilog -u _unresolved -Wl,--gc-sections -nostdlib -g $(MACHDEP) -Wl,-Map,$(notdir $@).map

# Platform options
ifeq ($(VERSION),us0)
	CFLAGS += -DTP_US0
	CFLAGS += -D_BUILDID='"$(BUILDID)US0"'
	ASFLAGS += -DTP_US0
	GAMECODE = "RZDE"
	PRINTVER = "US0"
else ifeq ($(VERSION),us2)
	CFLAGS += -DTP_US2
	CFLAGS += -D_BUILDID='"$(BUILDID)US2"'
	ASFLAGS += -DTP_US2
	GAMECODE = "RZDE"
	PRINTVER = "US2"
else ifeq ($(VERSION),eu)
	CFLAGS += -DTP_EU
	CFLAGS += -D_BUILDID='"$(BUILDID)EU"'
	ASFLAGS += -DTP_EU
	GAMECODE = "RZDP"
	PRINTVER = "EU"
else ifeq ($(VERSION),jp)
	CFLAGS += -DTP_JP
	CFLAGS += -D_BUILDID='"$(BUILDID)JP"'
	ASFLAGS += -DTP_JP
	GAMECODE = "RZDJ"
	PRINTVER = "JP"
endif


#---------------------------------------------------------------------------------
# any extra libraries we wish to link with the project
#---------------------------------------------------------------------------------
LIBS	:= 

#---------------------------------------------------------------------------------
# list of directories containing libraries, this must be the top level containing
# include and lib
#---------------------------------------------------------------------------------
LIBDIRS	:= 

#---------------------------------------------------------------------------------
# no real need to edit anything past this point unless you need to add additional
# rules for different file extensions
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))
#---------------------------------------------------------------------------------

export OUTPUT	:=	$(CURDIR)/$(TARGET)

export VPATH	:=	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
			$(foreach dir,$(DATA),$(CURDIR)/$(dir))

export DEPSDIR	:=	$(CURDIR)/$(BUILD)

#---------------------------------------------------------------------------------
# automatically build a list of object files for our project
#---------------------------------------------------------------------------------
CFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES	:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
sFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))
SFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.S)))
BINFILES	:=	$(foreach dir,$(DATA),$(notdir $(wildcard $(dir)/*.*)))

#---------------------------------------------------------------------------------
# use CXX for linking C++ projects, CC for standard C
#---------------------------------------------------------------------------------
ifeq ($(strip $(CPPFILES)),)
	export LD	:=	$(CC)
else
	export LD	:=	$(CXX)
endif

export OFILES_BIN	:=	$(addsuffix .o,$(BINFILES))
export OFILES_SOURCES := $(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(sFILES:.s=.o) $(SFILES:.S=.o)
export OFILES := $(OFILES_BIN) $(OFILES_SOURCES)

export HFILES := $(addsuffix .h,$(subst .,_,$(BINFILES)))

# For REL linking
export LDFILES		:= $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.ld)))
export MAPFILE		:= $(realpath assets/$(VERSION).lst)
export BANNERFILE	:= $(realpath assets/banner.raw)
export ICONFILE		:= $(realpath assets/icon.raw)

#---------------------------------------------------------------------------------
# build a list of include paths
#---------------------------------------------------------------------------------
export INCLUDE	:=	$(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir)) \
			$(foreach dir,$(LIBDIRS),-I$(dir)/include) \
			-I$(CURDIR)/$(BUILD) \
			-I$(LIBOGC_INC)

#---------------------------------------------------------------------------------
# build a list of library paths
#---------------------------------------------------------------------------------
export LIBPATHS	:=	$(foreach dir,$(LIBDIRS),-L$(dir)/lib) \
			-L$(LIBOGC_LIB)

export OUTPUT	:=	$(CURDIR)/$(TARGET)
.PHONY: $(BUILD) clean_target

#---------------------------------------------------------------------------------
$(BUILD):
	@[ -d $@ ] || mkdir -p $@
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

#---------------------------------------------------------------------------------
clean_target:
	@echo clean ... $(VERSION)
	@rm -fr $(BUILD) $(OUTPUT).elf $(OUTPUT).dol $(OUTPUT).rel $(OUTPUT).bin

#---------------------------------------------------------------------------------
else

DEPENDS	:=	$(OFILES:.o=.d)

#---------------------------------------------------------------------------------
# main targets
#---------------------------------------------------------------------------------
$(OUTPUT).bin: $(OUTPUT).rel $(BANNERFILE)
$(OUTPUT).rel: $(OUTPUT).elf $(MAPFILE)
$(OUTPUT).elf: $(LDFILES) $(OFILES)

$(OFILES_SOURCES) : $(HFILES)

# REL linking
%.rel: %.elf
	@echo output ... $(notdir $@)
	@$(ELF2REL) $< -s $(MAPFILE)

%.bin: %.rel
	@[ -d $(BUILD) ] || mkdir -p $(BUILD)
	@echo formating ... $(notdir $(BUILD))/pcrel.bin
	@$(NANDPACK) format $< $(BUILD)/pcrel.bin
	@echo packing ... $(notdir $@)
	@$(NANDPACK) generate -g $(VERSION) -l 2 -f "$(PROJECT_NAME)" $< $(BANNERFILE) $@

#---------------------------------------------------------------------------------
# This rule links in binary data with the .jpg extension
#---------------------------------------------------------------------------------
%.jpg.o	%_jpg.h :	%.jpg
#---------------------------------------------------------------------------------
	@echo $(notdir $<)
	$(bin2o)

-include $(DEPENDS)

#---------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------
endif
