EXTRACTED_DRIVERS_5_2_6_5= \
	src/5.2.6-5/postflight.original \
	src/5.2.6-5/preflight.original \
	src/5.2.6-5/PenTablet.prefpane.original \
	src/5.2.6-5/com.wacom.pentablet.plist.original

PATCHED_DRIVERS_5_2_6_5= \
	src/5.2.6-5/postflight.patched \
	src/5.2.6-5/preflight.patched \
	src/5.2.6-5/PenTablet.prefpane.patched \
	src/5.2.6-5/com.wacom.pentablet.plist.patched

EXTRACTED_DRIVERS+= $(EXTRACTED_DRIVERS_5_2_6_5)

PATCHED_DRIVERS+= $(PATCHED_DRIVERS_5_2_6_5) 

FIX_SDK_5_2_6_5= \
	package/content.pkg/Payload/Applications/Pen\ Tablet.localized/Pen\ Tablet\ Utility.app/Contents/MacOS/Pen\ Tablet\ Utility

SIGN_ME_5_2_6_5= \
	package/content.pkg/Payload/Library/Application\ Support/Tablet/PenTabletDriver.app/Contents/Resources/TabletDriver.app \
	package/content.pkg/Payload/Library/Application\ Support/Tablet/PenTabletDriver.app/Contents/Resources/ConsumerTouchDriver.app \
	package/content.pkg/Payload/Library/Application\ Support/Tablet/PenTabletDriver.app \
	package/content.pkg/Payload/Library/Application\ Support/Tablet/PenTabletSpringboard.app \
	package/content.pkg/Payload/Library/Application\ Support/Tablet/Xtras/WacomDataXtra.xtra \
	package/content.pkg/Payload/Library/Application\ Support/Tablet/Xtras/WacomXtra.xtra \
	package/content.pkg/Payload/Library/Internet\ Plug-Ins/WacomNetscape.plugin \
	package/content.pkg/Payload/Library/Internet\ Plug-Ins/WacomTabletPlugin.plugin \
	package/content.pkg/Payload/Library/PreferencePanes/PenTablet.prefpane/Contents/MacOS/PenTablet \
	package/content.pkg/Payload/Library/PreferencePanes/PenTablet.prefPane \
	package/content.pkg/Payload/Library/Frameworks/WacomMultiTouch.framework/Versions/A/WacomMultiTouch \
	package/content.pkg/Payload/Applications/Pen\ Tablet.localized/Pen\ Tablet\ Utility.app \
	package/content.pkg/Scripts/renumtablets

UNSIGNED_INSTALLERS+= Install\ Wacom\ Tablet-5.2.6-5-patched-unsigned.pkg 
SIGNED_INSTALLERS+= Install\ Wacom\ Tablet-5.2.6-5-patched.pkg

# Create the installer package by modifying Wacom's original:

Install\ Wacom\ Tablet-5.2.6-5-patched-unsigned.pkg : src/5.2.6-5/Install\ Bamboo.pkg src/5.2.6-5/Welcome.rtf src/5.2.6-5/PackageInfo src/5.2.6-5/Distribution src/common-5/clearpermissions $(PATCHED_DRIVERS_5_2_6_5) src/5.3.7-6/renumtablets src/5.3.0-3/uninstall.pl.patched src/5.3.0-3/Pen\ Tablet\ Utility.app tools/fix_LC_VERSION_MIN_MACOSX/fixSDKVersion
	# Have to do a bunch of work here to upgrade the old-style directory package into a modern flat-file .pkg
	rm -rf package
	mkdir package
	mkdir package/content.pkg
	mkdir package/content.pkg/Payload
	mkdir package/content.pkg/Scripts

	cp -a -L src/5.2.6-5/Install\ Bamboo.pkg/Contents/Resources package/

	# Take 64-bit installer binaries from the subsequent 5.3.7-6 release to replace obsolete/unsignable 32-bit binaries in this release
	rm package/Resources/{InstallationCheck,renumtablets,SystemLoginItemTool}
	cp src/5.3.7-6/renumtablets package/content.pkg/Scripts/

	# Remove install scripts from old style directory
	rm package/Resources/{preflight,postflight}

	# Install patched postinstall script: Don't call old multitouch install method, use new language manifest loader code from 5.3.7-6, new agent loader
	cp src/5.2.6-5/postflight.patched package/content.pkg/Scripts/postflight
	# Tool for clearing leftover permissions from previous driver:
	cp src/common-5/clearpermissions package/content.pkg/Scripts/
	# New agent unloader
	cp src/5.2.6-5/preflight.patched  package/content.pkg/Scripts/preflight
	cp src/common-5/{unloadagent,loadagent} package/content.pkg/Scripts/

	# Add metadata files that weren't present in the old package style
	cp src/5.2.6-5/PackageInfo package/content.pkg
	cp src/5.2.6-5/Distribution package/

	# Add Welcome screen
	find package/Resources -type d -depth 1 -exec cp src/5.2.6-5/Welcome.rtf {}/ \;

	# Unpack payload
	cd package/content.pkg/Payload && tar --no-same-owner -xf ../../../src/5.2.6-5/Install\ Bamboo.pkg/Contents/Archive.pax.gz

	# Remove extended attribute files that didn't unpack properly (prevents codesigning if left there)
	find package/content.pkg/Payload -type f -name "._*" -delete

	# Avoid the old strategy of installing the multitouch framework to the /tmp directory first
	mv package/content.pkg/Payload/tmp/WacomMultiTouch.framework package/content.pkg/Payload/Library/Frameworks
	rm -r package/content.pkg/Payload/tmp

	# Remove PowerPC-only plugin
	rm -rf package/content.pkg/Payload/System/Library/Extensions/TabletDriverCFPlugin.bundle

	# Don't install files into the /System partition (not allowed in Catalina)
	mv package/content.pkg/Payload/System/Library/Extensions package/content.pkg/Payload/Library/
	rm -r package/content.pkg/Payload/System

	# Install fixed preference pane 
	cp src/5.2.6-5/PenTablet.prefpane.patched package/content.pkg/Payload/Library/PreferencePanes/PenTablet.prefPane/Contents/MacOS/PenTablet

	# Modify preference pane version number to avoid it getting marked as "incompatible software" by SystemMigration during system update
	plutil -replace CFBundleShortVersionString -string "5.2.6-5" package/content.pkg/Payload/Library/PreferencePanes/PenTablet.prefpane/Contents/Info.plist

	# Make duplicate copy of localisation strings to the location that the patched postflight script expects (documentation installation)
	cp -a -L package/Resources package/content.pkg/Scripts/support
	
	# Wrap the PenTabletSpringboard executable up into an app bundle, so we can refer to it by bundle ID in tccutil
	mkdir -p package/content.pkg/Payload/Library/Application\ Support/Tablet/PenTabletSpringboard.app/Contents/MacOS
	mv package/content.pkg/Payload/Library/Application\ Support/Tablet/PenTabletSpringboard package/content.pkg/Payload/Library/Application\ Support/Tablet/PenTabletSpringboard.app/Contents/MacOS/
	cp src/5.2.6-5/PenTabletSpringboard.Info.plist package/content.pkg/Payload/Library/Application\ Support/Tablet/PenTabletSpringboard.app/Contents/Info.plist

	# Update the LaunchAgent to refer to the new location for PenTabletSpringboard
	cp src/5.2.6-5/com.wacom.pentablet.plist.patched package/content.pkg/Payload/Library/LaunchAgents/com.wacom.pentablet.plist

	# Replace the 32-bit Bamboo Utility with the one from the Graphire 4 (they have identical uninstall.pl so this seems reasonable)
	rm -rf package/content.pkg/Payload/Applications/Pen\ Tablet.localized/Pen\ Tablet\ Utility.app
	cp -a src/5.3.0-3/Pen\ Tablet\ Utility.app package/content.pkg/Payload/Applications/Pen\ Tablet.localized/

	# Remove unused + unsignable old binary (not needed since 10.5)
	rm package/content.pkg/Payload/Applications/Pen\ Tablet.localized/Pen\ Tablet\ Utility.app/Contents/Resources/SystemLoginItemTool

	# Patch the uninstaller to remove the new location of PenTabletSpringboard
	cp src/5.3.0-3/uninstall.pl.patched package/content.pkg/Payload/Applications/Pen\ Tablet.localized/Pen\ Tablet\ Utility.app/Contents/Resources/uninstall.pl

	# Update minimum SDK versions to 10.9 to meet notarization requirements
	tools/fix_LC_VERSION_MIN_MACOSX/fixSDKVersion $(FIX_SDK_5_2_6_5)

ifdef CODE_SIGNING_IDENTITY
	# Resign drivers and enable Hardened Runtime to meet notarization requirements
	codesign -s "$(CODE_SIGNING_IDENTITY)" -f --options=runtime --timestamp $(SIGN_ME_5_2_6_5)
else
	codesign --remove-signature $(SIGN_ME_5_2_6_5)
endif

	# Recreate BOM
	mkbom package/content.pkg/Payload package/content.pkg/Bom

	# Repack payload
	( cd package/content.pkg/Payload && find . ! -path "./Library/Extensions*" ! -path "./Library/Frameworks*" | cpio -o --format odc --owner 0:80 ) > .tmp-payload

	# Have to remove the cpio trailer from the end of the first archive (to allow the second archive to be appended)
	# - it'd be nice if macOS' cpio supported --append instead
	( \
		head -c $$(LC_CTYPE=C grep --byte-offset --only-matching --text -F '0707070000000000000000000000000000000000010000000000000000000001300000000000TRAILER!!!' .tmp-payload | cut -f1 -d: ) .tmp-payload ; \
		( cd package/content.pkg/Payload && find ./Library/Extensions ./Library/Frameworks | cpio -o --format odc --owner 0:0 ) ; \
	) | gzip -c > package/content.pkg/Payload.gz
	rm .tmp-payload
	rm -rf package/content.pkg/Payload
	mv package/content.pkg/Payload.gz package/content.pkg/Payload

	# Repack installer
	pkgutil --flatten package "$@"

src/5.2.6-5/PenTablet.prefpane.patched : src/5.2.6-5/PenTablet.prefpane.patch src/5.2.6-5/PenTablet.prefpane.original src/5.2.6-5/PenTablet.prefpane.newcode.bin src/5.2.6-5/PenTablet.prefpane.newdata.bin src/5.2.6-5/PenTablet.prefpane.beginDialog.bin src/5.2.6-5/PenTablet.prefpane.getCurrentController.bin .venv/
	# Apply diff patches:
	cp src/5.2.6-5/PenTablet.prefpane.original $@
	patch $@ < src/5.2.6-5/PenTablet.prefpane.patch
	# Strip fat binary: (don't need 32-bit or PPC variants)
	lipo -thin x86_64 $@ -output $@.1
	mv $@.1 $@
	./.venv/bin/python3 tools/extend-mach-o/append-section.py $@ $@.1 __MONKEYCODE __monkeycode src/5.2.6-5/PenTablet.prefpane.newcode.bin 5
	./.venv/bin/python3 tools/extend-mach-o/append-section.py $@.1 $@ __MONKEYDATA __monkeydata src/5.2.6-5/PenTablet.prefpane.newdata.bin 3
	# Patch calls to NSApp::mainWindow:
	dd if=src/5.2.6-5/PenTablet.prefpane.beginDialog.bin          of=$@ bs=1 seek=$$((0x0002ceb1)) conv=notrunc
	dd if=src/5.2.6-5/PenTablet.prefpane.getCurrentController.bin of=$@ bs=1 seek=$$((0x0002cddf)) conv=notrunc

ifdef PACKAGE_SIGNING_IDENTITY
Install\ Wacom\ Tablet-5.2.6-5-patched.pkg : Install\ Wacom\ Tablet-5.2.6-5-patched-unsigned.pkg
	productsign --sign "$(PACKAGE_SIGNING_IDENTITY)" Install\ Wacom\ Tablet-5.2.6-5-patched-unsigned.pkg Install\ Wacom\ Tablet-5.2.6-5-patched.pkg
endif

# Download, mount and unpack original Wacom installers:

src/5.2.6-5/PenTablet_5.2.6-5.dmg :
	curl -o $@ "https://cdn.wacom.com/U/productsupport/Drivers/Mac/Consumer/PenTablet_5.2.6-5.dmg"
	[ $$(md5 $@ | awk '{ print $$4 }') = "548d92f2a55e6f17c63242f5e7a521fa" ] || (rm $@; false) # Verify download is undamaged

src/5.2.6-5/Install\ Bamboo.pkg : src/5.2.6-5/PenTablet_5.2.6-5.dmg
	hdiutil attach -quiet -nobrowse -mountpoint src/5.2.6-5/dmg "$<"
	rm -rf "$@"
	cp -a "src/5.2.6-5/dmg/Install Bamboo.pkg" "$@"
	# The permissions on the package files are super awkward, make those more permissive for us:
	find "src/5.2.6-5/Install Bamboo.pkg" -type d -exec chmod 0755 {} \;
	find "src/5.2.6-5/Install Bamboo.pkg" -type f -exec chmod u+rw {} \;
	# Also copy the directories from outside the package because we need them for getting licence files
	cp -R src/5.2.6-5/dmg/{ChineseS,ChineseT,Dutch,English,French,German,Italian,Japanese,Korean,Polish,Portuguese,Russian,Spanish} src/5.2.6-5/
	hdiutil detach -force src/5.2.6-5/dmg
	touch "$@"

# Extract original files from the Wacom installers as needed:

$(EXTRACTED_DRIVERS_5_2_6_5) : src/5.2.6-5/Install\ Bamboo.pkg
	rm -rf src/5.2.6-5/Install\ Bamboo.pkg/Contents/Archive
	mkdir -p src/5.2.6-5/Install\ Bamboo.pkg/Contents/Archive
	cd src/5.2.6-5/Install\ Bamboo.pkg/Contents/Archive && tar --no-same-owner -xf ../Archive.pax.gz
	cp src/5.2.6-5/Install\ Bamboo.pkg/Contents/Resources/postflight src/5.2.6-5/postflight.original
	cp src/5.2.6-5/Install\ Bamboo.pkg/Contents/Resources/preflight  src/5.2.6-5/preflight.original
	cp src/5.2.6-5/Install\ Bamboo.pkg/Contents/Archive/Library/PreferencePanes/PenTablet.prefpane/Contents/MacOS/PenTablet src/5.2.6-5/PenTablet.prefpane.original
	cp src/5.2.6-5/Install\ Bamboo.pkg/Contents/Archive/Library/LaunchAgents/com.wacom.pentablet.plist src/5.2.6-5/com.wacom.pentablet.plist.original
	cp src/5.2.6-5/Install\ Bamboo.pkg/Contents/Archive/Applications/Pen\ Tablet.localized/Pen\ Tablet\ Utility.app/Contents/Resources/uninstall.pl src/5.2.6-5/uninstall.pl.original

# Utility commands:

ifdef NOTARIZATION_KEYCHAIN_PROFILE
notarize-graphire3: Install\ Wacom\ Tablet-5.2.6-5-patched.pkg
	xcrun notarytool \
		submit \
		--keychain-profile $(NOTARIZATION_KEYCHAIN_PROFILE) \
		"$<"
	cp "$<" "Install Wacom Tablet-5.2.6-5-patched-notarized.pkg"
endif

staple-graphire3:
	xcrun stapler staple "Install Wacom Tablet-5.2.6-5-patched.pkg"
	cp "Install Wacom Tablet-5.2.6-5-patched.pkg" "Install Wacom Tablet-5.2.6-5-patched-stapled.pkg"

unpack-graphire3 : src/5.2.6-5/Install\ Bamboo.pkg
	mkdir -p src/5.2.6-5/Install\ Bamboo.pkg/Contents/Archive
	cd src/5.2.6-5/Install\ Bamboo.pkg/Contents/Archive && tar --no-same-owner -xf ../Archive.pax.gz
