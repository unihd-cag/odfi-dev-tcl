## This makefile downloads and compiles TCl and dependent libraries for Extoll TCL interfaces
## 

## Distribution description
DIST_INSTALL_PACKAGES_DEPS_APT += libxslt-dev libxml2-dev
DIST_INSTALL_PACKAGES_DEPS_YUM += libxml2-devel libxslt-devel
include $(ODFI_MBUILD_HOME)/sw/makefile/Makefile.dist
DIST_VERSION := 1.0.0

## Packaging
dist: tcl8.5.11-src.tar.gz tclxml-3.2.tar.gz itcl3.4.1.tar.gz tcllib-1.14.tar.gz
	$(dist-module-prepare-work)
	@echo "-- Preparing TCL interpreter distribution"
	@echo "-- Done Downloading all the required packages . This makefile has been written to use downloaded packages and not redownload when installing"
	@echo "-- Packaging: $^"
	@$(call dist-module-add,$^)
	$(dist-module-package)
	
	
tcl8.5.11-src.tar.gz:
	@wget "http://prdownloads.sourceforge.net/tcl/tcl8.5.11-src.tar.gz"

tclxml-3.2.tar.gz:
	@wget "http://prdownloads.sourceforge.net/tclxml/tclxml-3.2.tar.gz"

itcl3.4.1.tar.gz:
	@wget -O itcl3.4.1.tar.gz  "http://downloads.sourceforge.net/project/incrtcl/%5BIncr%20Tcl_Tk%5D-source/3.4.1/itcl3.4.1.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fincrtcl%2Ffiles%2F%255BIncr%2520Tcl_Tk%255D-source%2F3.4.1%2F&ts=1331547265&use_mirror=netcologne"

tcllib-1.14.tar.gz:
	@wget -O tcllib-1.14.tar.gz "http://downloads.sourceforge.net/project/tcllib/tcllib/1.14/tcllib-1.14.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Ftcllib%2Ffiles%2Ftcllib%2F1.14%2F&ts=1331551099&use_mirror=freefr"
	
## Install does everything
#########################

PREFIX ?= $(shell pwd)

install : dist_install_prepare packages folders all_tcl all_tclxml all_itcl all_tcllib

## Clean Deletes compilation results
#clean: clean_tcl clean_tclxml

## mrproper : Destroy everything (all folders apart from this Makefile)
mrproper:
	@echo "Cleaning folder completely (only makefile remains)"
	rm --preserve-root -Rf `ls --hide="Makefile"`
	

## Common
################

## Install required packages and download sources
packages:  tclxml-3.2.tar.gz itcl3.4.1.tar.gz tcllib-1.14.tar.gz
	@echo "Install required packages: libxml2-dev libxslt-dev"
	

## Folder prepares folders
folders: 
	@echo "Preparing base folders..."
	@if [[ ! -d bin/ ]]; then mkdir -v bin/ ; fi;
	@if [[ ! -d include/ ]]; then mkdir -v include/ ; fi;
	@if [[ ! -d lib/ ]]; then mkdir -v lib/ ; fi;
	@if [[ ! -d working/ ]]; then mkdir -v working/ ; fi;


## TCL
####################
all_tcl: bin/tclsh 

# Extract and make
bin/tclsh:	bin/tclsh8.5
	@ln -f -s bin/tclsh8.5 bin/tclsh
	
bin/tclsh8.5: working/tcl8.5.11/unix/Makefile
	@echo "Making TCL"
	@cd working/tcl8.5.11/unix && make && make install

# configure
working/tcl8.5.11/unix/Makefile: working/tcl8.5.11-src.tar.gz
	@echo "Configuring TCL"
	@cd working && tar xvzf tcl8.5.11-src.tar.gz && cd tcl8.5.11/unix && ./configure --prefix=$(PREFIX)

# Download TCL
working/tcl8.5.11-src.tar.gz: tcl8.5.11-src.tar.gz
	@echo "Found TCL 8.5.11 sources"
	@cp $^ working



## TCl XML
####################
all_tclxml: working/tclxml-3.2.tar.gz lib/Tclxml3.2/libTclxml3.2.so


# Make
lib/Tclxml3.2/libTclxml3.2.so: working/tclxml-3.2/Makefile
	@echo "Making TCL XML"
	@cd working/tclxml-3.2/ && make && make install
	
# Configure
working/tclxml-3.2/Makefile:
	@echo "Configuring TCL XML"
	@cd working && tar xvzf tclxml-3.2.tar.gz && cd tclxml-3.2/ && ./configure --prefix=$(PREFIX)

# Download
working/tclxml-3.2.tar.gz: tclxml-3.2.tar.gz
	@echo "Found TCL XML 3.2 sources"
	@cp $^ working	
	
## iTCL
##########################
all_itcl: lib/itcl3.4/libitcl3.4.so

lib/itcl3.4/libitcl3.4.so : working/itcl3.4.1/Makefile
	@echo "Making iTCL"
	@cd working && cd itcl3.4.1/ && make && make install

working/itcl3.4.1/Makefile: working/itcl3.4.1.tar.gz
	@echo "Configuring iTCL"
	@cd working && tar xvzf itcl3.4.1.tar.gz && cd itcl3.4.1/ && ./configure --prefix=$(PREFIX)

working/itcl3.4.1.tar.gz: itcl3.4.1.tar.gz
	@echo "Found iTCL"
	@cp $^ working
	

## TCL lib
###############################
all_tcllib: working/tcllib-1.14/Makefile
	@echo "Making TCL Lib"
	@cd working/tcllib-1.14 && make && make install
	
working/tcllib-1.14/Makefile: working/tcllib-1.14.tar.gz
	@echo "Configuring TCL Lib"
	@cd working && tar xvzf tcllib-1.14.tar.gz && cd tcllib-1.14  && ./configure --prefix=$(PREFIX)
	
working/tcllib-1.14.tar.gz: tcllib-1.14.tar.gz
	@echo "Found tcllib"
	@cp $^ working
	
	
