#!/bin/bash
# title         init_apt_cyg.sh
# author        bstoots@thewildstoat.com
# description   Cygwin configuration script that will automatically install
#               apt-cyg (https://code.google.com/p/apt-cyg/) and optionally
#               install user defined packages from init_apt_cyg_packages.txt

###############################################################################
# Functions
###############################################################################
error() {
  echo "Error in script on line $1 status: $2"
  exit 1
}

invalid() {
  echo "Invalid value for variable: $1, value: $2"
  exit 2
}

###############################################################################
# Config
###############################################################################
# Snag the currently executing script's full path
SCRIPT_PATH="`dirname \"$0\"`"
SCRIPT_PATH="`( cd \"$SCRIPT_PATH\" && pwd )`"
# If there's a packages file where does that thing live?  Default is same
# directory as this script
PACKAGES_FILE=$SCRIPT_PATH/init_apt_cyg_packages.txt

###############################################################################
# Get Some
###############################################################################

# Only attempt install if apt-cyg is not already installed
which apt-cyg > /dev/null 2>&1
if [ $? -ne 0 ]; then
  # Go fetch apt-cyg from Subversion ... you installed Subversion with Cygwin right?
  which svn > /dev/null 2>&1
  STATUS=$?; if [ $STATUS -ne 0 ]; then error $(($LINENO - 1)) $STATUS; fi
  which wget > /dev/null 2>&1
  STATUS=$?; if [ $STATUS -ne 0 ]; then error $(($LINENO - 1)) $STATUS; fi
  # Do eet
  svn --force export http://apt-cyg.googlecode.com/svn/trunk/ /bin/
  STATUS=$?; if [ $STATUS -ne 0 ]; then error $(($LINENO - 1)) $STATUS; fi
  chmod +x /bin/apt-cyg
  STATUS=$?; if [ $STATUS -ne 0 ]; then error $(($LINENO - 1)) $STATUS; fi  
fi

# If an init_apt_cyg_packages.txt file exists read in a list of packages to pass
# to apt-cyg for auto-magic install.  These must be specified one per line and 
# each line must end in a newline
if [ -s $PACKAGES_FILE ]; then
  while read PACKAGE; do 
  PACKAGES+=$PACKAGE" "
  done < $PACKAGES_FILE
  # Install the packages via apt-cyg
  apt-cyg install $PACKAGES
  STATUS=$?; if [ $STATUS -ne 0 ]; then error $(($LINENO - 1)) $STATUS; fi  
fi
