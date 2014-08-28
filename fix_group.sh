#!/bin/bash
# title         fix_group.sh
# author        bstoots@thewildstoat.com
# description   Cygwin configuration script that fixes the default GID of the
#               current user, changing it to a built-in Windows group other
#               other than the place-holder group of "None".  Also changes
#               group ownership on existing files that were created by Cygwin

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
# Group owner for all files Cygwin created and all future files created by
# the current user
GROUP="Users"
# Note: Don't put /, /cygdrive, or /proc in here bad things happen
DIRS=("/bin" "/dev" "/etc" "/home" "/lib" "/packages" "/tmp" "/usr" "/var")

###############################################################################
# Get Some
###############################################################################

# Snag current user's UID if it's not already set
if [ -z $UID ]; then
  UID=`id -u`
  STATUS=$?; if [ $STATUS -ne 0 ]; then error $(($LINENO - 1)) $STATUS; fi
fi
if [ -z $UID ]; then invalid UID $UID; fi

# Snag user name for mkpasswd
USER=`id -u -n`
STATUS=$?; if [ $STATUS -ne 0 ]; then error $(($LINENO - 1)) $STATUS; fi
if [ -z $USER ]; then invalid USER $USER; fi

# Snag the corresponding from /etc/passwd and just escape it now
MKPASSWD_ROW=$(mkpasswd -l -u $USER | sed 's/[]\/$*.^|[]/\\&/g')
STATUS=$?; if [ $STATUS -ne 0 ]; then error $(($LINENO - 1)) $STATUS; fi
if [ -z $MKPASSWD_ROW ]; then invalid MKPASSWD_ROW $MKPASSWD_ROW; fi

# Snag the GID for $GROUP
GID=`cat /etc/group | egrep ^$GROUP: | cut -d ":" -f 3`
if [ -z $GID ]; then invalid GID $GID; fi

# Make new row by swapping GIDs in the PASSWD_ROW
NEW_MKPASSWD_ROW=$(echo $MKPASSWD_ROW | cut -d ":" -f -3):$GID:$(echo $MKPASSWD_ROW | cut -d ":" -f 5-)
STATUS=$?; if [ $STATUS -ne 0 ]; then error $(($LINENO - 1)) $STATUS; fi
if [ -z $NEW_MKPASSWD_ROW ]; then invalid NEW_MKPASSWD_ROW $NEW_MKPASSWD_ROW; fi

# Do the dangerous dangerous sed operation
cp /etc/passwd /etc/passwd_bak
# If copy didn't succeed get out of here
STATUS=$?; if [ $STATUS -ne 0 ]; then error $(($LINENO - 2)) $STATUS; fi
# Alright, hop to it spanky
sed -i "s/$MKPASSWD_ROW/$NEW_MKPASSWD_ROW/" /etc/passwd
STATUS=$?; if [ $STATUS -ne 0 ]; then error $(($LINENO - 1)) $STATUS; fi

# Do the chgrp mambo
echo "chgrp $GID /"
chgrp $GID /
STATUS=$?; if [ $STATUS -ne 0 ]; then error $(($LINENO - 1)) $STATUS; fi
for DIR in ${DIRS[@]}
do :
  echo "chgrp -R $GID $DIR"
  chgrp -R $GID $DIR
  STATUS=$?; if [ $STATUS -ne 0 ]; then error $(($LINENO - 1)) $STATUS; fi
done
