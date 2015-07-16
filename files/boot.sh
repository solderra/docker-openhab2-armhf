#!/bin/bash

CONFIG_DIR=/etc/openhab/

####################
# Configure timezone

TIMEZONEFILE=$CONFIG_DIR/timezone

if [ -f "$TIMEZONEFILE" ]
then
  cp $TIMEZONEFILE /etc/timezone
  dpkg-reconfigure -f noninteractive tzdata
fi

###########################
# Configure Addon libraries

SOURCE=/opt/openhab/addons-available
DEST=/opt/openhab/addons
ADDONFILE=$CONFIG_DIR/addons.cfg

function addons {
  # Remove all links first
  rm $DEST/*

  # create new links based on input file
  while read STRING
  do
    STRING=${STRING%$'\r'}
    echo Processing $STRING...
    if [ -f $SOURCE/addons/$STRING*.jar ]
    then
      ln -s $SOURCE/addons/$STRING*.jar $DEST/
      echo link created.
    else
      echo not found.
    fi
  done < "$ADDONFILE"
}

if [ -f "$ADDONFILE" ]
then
  addons
else
  echo addons.cfg not found.
fi

# copy example add-on configuration files if EXAMPLE_CONF is set
if [ "$EXAMPLE_CONF" ]
then
	cp -Rn $SOURCE/conf/* $CONFIG_DIR/
fi

###########################################
# Configure demo if no configuration is given (if volume is not mapped on /etc/openhab then DEMO_MODE file is not over-written) 

if [ ! -f "$CONFIG_DIR/DEMO_MODE" ]
then
  echo configuration found.
#  rm -rf /tmp/demo-openhab*
else
  echo --------------------------------------------------------
  echo          NO openhab.cfg CONFIGURATION FOUND
  echo
  echo                = using demo files =
  echo
  echo Consider running the Docker with a openhab configuration
  echo 
  echo --------------------------------------------------------
  cp -R /opt/openhab/demo-configuration/conf/* /etc/openhab/
  ln -s /opt/openhab/demo-configuration/addons/* /opt/openhab/addons/
#  ln -s /etc/openhab/openhab_default.cfg /etc/openhab/openhab.cfg
fi

######################
# Decide how to launch

ETH0_FOUND=`grep "eth0" /proc/net/dev`

if [ -n "$ETH0_FOUND" ] ;
then 
  # We're in a container with regular eth0 (default)
  exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
else 
  # We're in a container without initial network.  Wait for it...
  /usr/local/bin/pipework --wait
  exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
fi
