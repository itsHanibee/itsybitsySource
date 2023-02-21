# Set to true if you do *NOT* want Magisk to mount
# any files for you. Most modules would NOT want
# to set this flag to true
SKIPMOUNT=false

# Set to true if you need to load system.prop
PROPFILE=true

# Set to true if you need post-fs-data script
POSTFSDATA=false

# Set to true if you need late_start service script
LATESTARTSERVICE=true

# Set what you want to display when installing your module

print_modname() {
  ui_print " "
  MNAME=`grep_prop name $TMPDIR/module.prop`
  ui_print " $MNAME"
  ui_print " "
  MVERSION=`grep_prop version $TMPDIR/module.prop`
  MVERSIONCODE=`grep_prop versionCode $TMPDIR/module.prop`
  ui_print " ⚀	ID = $MODID"
  sleep 0.2
  ui_print " ⚁	Version = $MVERSION"
  sleep 0.3
  ui_print " ⚂	VersionCode = $MVERSIONCODE"
  sleep 0.4
  ui_print " ⚃	MagiskVersion = $MAGISK_VER"
  sleep 0.5
  ui_print " ⚄	MagiskVersionCode = $MAGISK_VER_CODE"
  sleep 0.7
  ui_print " "
  ui_print " ⚅	Device SDK = $API"
}
sleep 1

on_install() {
	
  # Extend/change the logic to whatever you want
  MIN=29
  ui_print " >------------------<"
  ui_print " ⛌	Minimum SDK = $MIN"
  if [ "$API" -lt $MIN ]; then
    ui_print " "
    ui_print "   Your device isn't running Android 10+"
    ui_print "   Device requirements not met, installation aborting..."
    abort
  else
ui_print " "
ui_print " ⛑ Please Wait..."
sleep 3
	
    ui_print " "
    ui_print "   Module installed! Restart when ready 🥳"
    unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2
    ui_print " "
  fi
}

# Set permissions
set_perm_recursive $MODPATH 0 0 0755 0644
if [ -d $MODPATH/system/vendor ]; then
  set_perm_recursive $MODPATH/system/vendor 0 0 0755 0644 u:object_r:vendor_file:s0
  [ -d $MODPATH/system/vendor/app ] && set_perm_recursive $MODPATH/system/vendor/app 0 0 0755 0644 u:object_r:vendor_app_file:s0
  [ -d $MODPATH/system/vendor/etc ] && set_perm_recursive $MODPATH/system/vendor/etc 0 0 0755 0644 u:object_r:vendor_configs_file:s0
  [ -d $MODPATH/system/vendor/overlay ] && set_perm_recursive $MODPATH/system/vendor/overlay 0 0 0755 0644 u:object_r:vendor_overlay_file:s0
  for FILE in $(find $MODPATH/system/vendor -type f -name *".apk"); do
    [ -f $FILE ] && chcon u:object_r:vendor_app_file:s0 $FILE
  done
fi
set_permissions

# Complete install
cleanup
