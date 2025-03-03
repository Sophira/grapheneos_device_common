# Copyright 2011 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Use the default values if they weren't explicitly set
if test "$XLOADERSRC" = ""
then
  XLOADERSRC=xloader.img
fi
if test "$BOOTLOADERSRC" = ""
then
  BOOTLOADERSRC=bootloader.img
fi
if test "$RADIOSRC" = ""
then
  RADIOSRC=radio.img
fi
if test "$SLEEPDURATION" = ""
then
  SLEEPDURATION=5
fi

# Prepare the staging directory
rm -rf tmp
mkdir -p tmp/$PRODUCT-$VERSION

# Extract the bootloader(s) and radio(s) as necessary
if test "$XLOADER" != ""
then
  unzip -d tmp ${SRCPREFIX}$PRODUCT-target_files-$BUILD.zip RADIO/$XLOADERSRC
fi
if test "$BOOTLOADERFILE" = ""
then
  unzip -d tmp ${SRCPREFIX}$PRODUCT-target_files-$BUILD.zip RADIO/$BOOTLOADERSRC
fi
if test "$RADIO" != "" -a "$RADIOFILE" = ""
then
  unzip -d tmp ${SRCPREFIX}$PRODUCT-target_files-$BUILD.zip RADIO/$RADIOSRC
fi
if test "$CDMARADIO" != "" -a "$CDMARADIOFILE" = ""
then
  unzip -d tmp ${SRCPREFIX}$PRODUCT-target_files-$BUILD.zip RADIO/radio-cdma.img
fi

# Copy the various images in their staging location
cp ${SRCPREFIX}$PRODUCT-img-$BUILD.zip tmp/$PRODUCT-$VERSION/image-$PRODUCT-$VERSION.zip
if test "$XLOADER" != ""
then
  cp tmp/RADIO/$XLOADERSRC tmp/$PRODUCT-$VERSION/xloader-$DEVICE-$XLOADER.img
fi
if test "$BOOTLOADERFILE" = ""
then
  cp tmp/RADIO/$BOOTLOADERSRC tmp/$PRODUCT-$VERSION/bootloader-$DEVICE-$BOOTLOADER.img
else
  cp $BOOTLOADERFILE tmp/$PRODUCT-$VERSION/bootloader-$DEVICE-$BOOTLOADER.img
fi
if test "$RADIO" != ""
then
  if test "$RADIOFILE" = ""
  then
    cp tmp/RADIO/$RADIOSRC tmp/$PRODUCT-$VERSION/radio-$DEVICE-$RADIO.img
  else
    cp $RADIOFILE tmp/$PRODUCT-$VERSION/radio-$DEVICE-$RADIO.img
  fi
fi
if test "$CDMARADIO" != ""
then
  if test "$CDMARADIOFILE" = ""
  then
    cp tmp/RADIO/radio-cdma.img tmp/$PRODUCT-$VERSION/radio-cdma-$DEVICE-$CDMARADIO.img
  else
    cp $CDMARADIOFILE tmp/$PRODUCT-$VERSION/radio-cdma-$DEVICE-$CDMARADIO.img
  fi
fi
if test "$AVB_PKMD" != ""
then
  cp "$AVB_PKMD" tmp/$PRODUCT-$VERSION/avb_pkmd.bin
fi

# Write flash-all.sh
cat > tmp/$PRODUCT-$VERSION/flash-all.sh << EOF
#!/bin/sh

#    SSSSSSSSSSSSSSS  TTTTTTTTTTTTTTTTTTTTTTT      OOOOOOOOO      PPPPPPPPPPPPPPPPP
#  SS:::::::::::::::S T:::::::::::::::::::::T    OO:::::::::OO    P::::::::::::::::P
# S:::::SSSSSS::::::S T:::::::::::::::::::::T  OO:::::::::::::OO  P::::::PPPPPP:::::P
# S:::::S     SSSSSSS T:::::TT:::::::TT:::::T O:::::::OOO:::::::O PP:::::P     P:::::P
# S:::::S             TTTTTT  T:::::T  TTTTTT O::::::O   O::::::O   P::::P     P:::::P
# S:::::S                     T:::::T         O:::::O     O:::::O   P::::P     P:::::P
#  S::::SSSS                  T:::::T         O:::::O     O:::::O   P::::PPPPPP:::::P
#   SS::::::SSSSS             T:::::T         O:::::O     O:::::O   P:::::::::::::PP
#     SSS::::::::SS           T:::::T         O:::::O     O:::::O   P::::PPPPPPPPP
#        SSSSSS::::S          T:::::T         O:::::O     O:::::O   P::::P
#             S:::::S         T:::::T         O:::::O     O:::::O   P::::P
#             S:::::S         T:::::T         O::::::O   O::::::O   P::::P
# SSSSSSS     S:::::S       TT:::::::TT       O:::::::OOO:::::::O PP::::::PP
# S::::::SSSSSS:::::S       T:::::::::T        OO:::::::::::::OO  P::::::::P
# S:::::::::::::::SS        T:::::::::T          OO:::::::::OO    P::::::::P
#  SSSSSSSSSSSSSSS          TTTTTTTTTTT            OOOOOOOOO      PPPPPPPPPP
#
# DO NOT EDIT THIS FILE. THE OFFICIAL GRAPHENEOS INSTALL GUIDE WILL NEVER INSTRUCT YOU
# TO EDIT THIS FILE. IF YOU ARE FOLLOWING A 3RD PARTY GUIDE YOU SHOULD STOP IMMEDIATELY
# AND START OVER AND FOLLOW THE OFFICIAL INSTALLATION PROCESS ON THE OFFICIAL WEBSITE.
# USING THE WEB INSTALLER IS STRONGLY RECOMMENDED https://grapheneos.org/install/web
# THE CLI INSTALLATION PROCESS SHOULD ONLY BE USED BY USERS WITH SPECIFIC NEEDS.

# Copyright 2012 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

if ! command -v fastboot > /dev/null; then
  echo "fastboot not found; please download the latest version at https://developer.android.com/studio/releases/platform-tools.html and add it to the shell PATH"
  exit 1
fi

if ! [ \$("\$(which fastboot)" --version | grep "version" | cut -c18-23 | sed 's/\.//g' ) -ge 3303 ]; then
  echo "fastboot too old; please download the latest version at https://developer.android.com/studio/releases/platform-tools.html"
  exit 1
fi

product=\$(fastboot getvar product 2>&1 | head -1 | cut -d ' ' -f 2)
if ! [ \$product = $DEVICE ]; then
  echo "You're attempting to flash the wrong factory images. This would likely brick your device."
  echo
  echo "These factory images are for $DEVICE and the detected device is \$product."
  exit 1
fi

EOF
if test "$UNLOCKBOOTLOADER" = "true"
then
cat >> tmp/$PRODUCT-$VERSION/flash-all.sh << EOF
fastboot oem unlock
EOF
fi
if test "$ERASEALL" = "true"
then
cat >> tmp/$PRODUCT-$VERSION/flash-all.sh << EOF
fastboot erase boot
fastboot erase cache
fastboot erase recovery
fastboot erase system
fastboot erase userdata
EOF
fi
if test "$XLOADER" != ""
then
cat >> tmp/$PRODUCT-$VERSION/flash-all.sh << EOF
fastboot flash xloader xloader-$DEVICE-$XLOADER.img
EOF
fi
cat >> tmp/$PRODUCT-$VERSION/flash-all.sh << EOF
fastboot flash --slot=other bootloader bootloader-$DEVICE-$BOOTLOADER.img
fastboot --set-active=other
fastboot reboot-bootloader
sleep $SLEEPDURATION
fastboot flash --slot=other bootloader bootloader-$DEVICE-$BOOTLOADER.img
fastboot --set-active=other
EOF
if test "$TWINBOOTLOADERS" = "true"
then
cat >> tmp/$PRODUCT-$VERSION/flash-all.sh << EOF
fastboot flash bootloader2 bootloader-$DEVICE-$BOOTLOADER.img
EOF
fi
cat >> tmp/$PRODUCT-$VERSION/flash-all.sh << EOF
fastboot reboot-bootloader
sleep $SLEEPDURATION
EOF
if test "$RADIO" != ""
then
cat >> tmp/$PRODUCT-$VERSION/flash-all.sh << EOF
fastboot flash radio radio-$DEVICE-$RADIO.img
fastboot reboot-bootloader
sleep $SLEEPDURATION
EOF
fi
if test "$CDMARADIO" != ""
then
cat >> tmp/$PRODUCT-$VERSION/flash-all.sh << EOF
fastboot flash radio-cdma radio-cdma-$DEVICE-$CDMARADIO.img
fastboot reboot-bootloader
sleep $SLEEPDURATION
EOF
fi
if test "$AVB_PKMD" != ""
then
cat >> tmp/$PRODUCT-$VERSION/flash-all.sh << EOF
fastboot erase avb_custom_key
fastboot flash avb_custom_key avb_pkmd.bin
fastboot reboot-bootloader
sleep $SLEEPDURATION
EOF
fi
if test "$DISABLE_UART" = "true"
then
cat >> tmp/$PRODUCT-$VERSION/flash-all.sh << EOF
fastboot oem uart disable
EOF
fi
if test "$ERASE_APDP" = "true"
then
cat >> tmp/$PRODUCT-$VERSION/flash-all.sh << EOF
fastboot erase apdp_a
fastboot erase apdp_b
EOF
fi
if test "$ERASE_MSADP" = "true"
then
cat >> tmp/$PRODUCT-$VERSION/flash-all.sh << EOF
fastboot erase msadp_a
fastboot erase msadp_b
EOF
fi
if test "$DISABLE_FIPS" = "true"
then
cat >> tmp/$PRODUCT-$VERSION/flash-all.sh << EOF
fastboot erase fips
EOF
fi
if test "$DISABLE_DPM" = "true"
then
cat >> tmp/$PRODUCT-$VERSION/flash-all.sh << EOF
fastboot erase dpm_a
fastboot erase dpm_b
EOF
fi
cat >> tmp/$PRODUCT-$VERSION/flash-all.sh << EOF
fastboot snapshot-update cancel
fastboot -w --skip-reboot update image-$PRODUCT-$VERSION.zip
fastboot reboot-bootloader
sleep $SLEEPDURATION
EOF
chmod a+x tmp/$PRODUCT-$VERSION/flash-all.sh

# Write flash-all.bat
cat > tmp/$PRODUCT-$VERSION/flash-all.bat << EOF
@ECHO OFF
::    SSSSSSSSSSSSSSS  TTTTTTTTTTTTTTTTTTTTTTT      OOOOOOOOO      PPPPPPPPPPPPPPPPP
::  SS:::::::::::::::S T:::::::::::::::::::::T    OO:::::::::OO    P::::::::::::::::P
:: S:::::SSSSSS::::::S T:::::::::::::::::::::T  OO:::::::::::::OO  P::::::PPPPPP:::::P
:: S:::::S     SSSSSSS T:::::TT:::::::TT:::::T O:::::::OOO:::::::O PP:::::P     P:::::P
:: S:::::S             TTTTTT  T:::::T  TTTTTT O::::::O   O::::::O   P::::P     P:::::P
:: S:::::S                     T:::::T         O:::::O     O:::::O   P::::P     P:::::P
::  S::::SSSS                  T:::::T         O:::::O     O:::::O   P::::PPPPPP:::::P
::   SS::::::SSSSS             T:::::T         O:::::O     O:::::O   P:::::::::::::PP
::     SSS::::::::SS           T:::::T         O:::::O     O:::::O   P::::PPPPPPPPP
::        SSSSSS::::S          T:::::T         O:::::O     O:::::O   P::::P
::             S:::::S         T:::::T         O:::::O     O:::::O   P::::P
::             S:::::S         T:::::T         O::::::O   O::::::O   P::::P
:: SSSSSSS     S:::::S       TT:::::::TT       O:::::::OOO:::::::O PP::::::PP
:: S::::::SSSSSS:::::S       T:::::::::T        OO:::::::::::::OO  P::::::::P
:: S:::::::::::::::SS        T:::::::::T          OO:::::::::OO    P::::::::P
::  SSSSSSSSSSSSSSS          TTTTTTTTTTT            OOOOOOOOO      PPPPPPPPPP
::
:: DO NOT EDIT THIS FILE. THE OFFICIAL GRAPHENEOS INSTALL GUIDE WILL NEVER INSTRUCT YOU
:: TO EDIT THIS FILE. IF YOU ARE FOLLOWING A 3RD PARTY GUIDE YOU SHOULD STOP IMMEDIATELY
:: AND START OVER AND FOLLOW THE OFFICIAL INSTALLATION PROCESS ON THE OFFICIAL WEBSITE.
:: USING THE WEB INSTALLER IS STRONGLY RECOMMENDED https://grapheneos.org/install/web
:: THE CLI INSTALLATION PROCESS SHOULD ONLY BE USED BY USERS WITH SPECIFIC NEEDS.

:: Copyright 2012 The Android Open Source Project
::
:: Licensed under the Apache License, Version 2.0 (the "License");
:: you may not use this file except in compliance with the License.
:: You may obtain a copy of the License at
::
::      http://www.apache.org/licenses/LICENSE-2.0
::
:: Unless required by applicable law or agreed to in writing, software
:: distributed under the License is distributed on an "AS IS" BASIS,
:: WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
:: See the License for the specific language governing permissions and
:: limitations under the License.

PATH=%PATH%;"%SYSTEMROOT%\System32"

:: Detect Fastboot version with inline PowerShell
:: Should work with Windows 7 and later

where /q fastboot || ECHO fastboot not found; please download the latest version at https://developer.android.com/studio/releases/platform-tools.html and add it to the shell PATH && EXIT /B

@PowerShell ^
\$version=fastboot --version; ^
try { ^
    \$verNum = \$version[0].substring(17, 6); ^
    \$verNum = \$verNum.replace('.', ''); ^
    if ((-Not (\$verNum -ge 3103)) -Or (-Not (\$verNum -match '^[\d.]+$'))) { ^
        Exit 1 ^
    } ^
} catch { ^
    Exit 1 ^
}

IF %ERRORLEVEL% NEQ 0 (
  ECHO fastboot too old; please download the latest version at https://developer.android.com/studio/releases/platform-tools.html
  EXIT /B
)

EOF
if test "$UNLOCKBOOTLOADER" = "true"
then
cat >> tmp/$PRODUCT-$VERSION/flash-all.bat << EOF
fastboot oem unlock
EOF
fi
if test "$ERASEALL" = "true"
then
cat >> tmp/$PRODUCT-$VERSION/flash-all.bat << EOF
fastboot erase boot
fastboot erase cache
fastboot erase recovery
fastboot erase system
fastboot erase userdata
EOF
fi
if test "$XLOADER" != ""
then
cat >> tmp/$PRODUCT-$VERSION/flash-all.bat << EOF
fastboot flash xloader xloader-$DEVICE-$XLOADER.img
EOF
fi
cat >> tmp/$PRODUCT-$VERSION/flash-all.bat << EOF
fastboot flash --slot=other bootloader bootloader-$DEVICE-$BOOTLOADER.img
fastboot --set-active=other
fastboot reboot-bootloader
ping -n $SLEEPDURATION 127.0.0.1 >nul
fastboot flash --slot=other bootloader bootloader-$DEVICE-$BOOTLOADER.img
fastboot --set-active=other
EOF
if test "$TWINBOOTLOADERS" = "true"
then
cat >> tmp/$PRODUCT-$VERSION/flash-all.bat << EOF
fastboot flash bootloader2 bootloader-$DEVICE-$BOOTLOADER.img
EOF
fi
cat >> tmp/$PRODUCT-$VERSION/flash-all.bat << EOF
fastboot reboot-bootloader
ping -n $SLEEPDURATION 127.0.0.1 >nul
EOF
if test "$RADIO" != ""
then
cat >> tmp/$PRODUCT-$VERSION/flash-all.bat << EOF
fastboot flash radio radio-$DEVICE-$RADIO.img
fastboot reboot-bootloader
ping -n $SLEEPDURATION 127.0.0.1 >nul
EOF
fi
if test "$CDMARADIO" != ""
then
cat >> tmp/$PRODUCT-$VERSION/flash-all.bat << EOF
fastboot flash radio-cdma radio-cdma-$DEVICE-$CDMARADIO.img
fastboot reboot-bootloader
ping -n $SLEEPDURATION 127.0.0.1 >nul
EOF
fi
if test "$AVB_PKMD" != ""
then
cat >> tmp/$PRODUCT-$VERSION/flash-all.bat << EOF
fastboot erase avb_custom_key
fastboot flash avb_custom_key avb_pkmd.bin
fastboot reboot-bootloader
ping -n $SLEEPDURATION 127.0.0.1 >nul
EOF
fi
if test "$DISABLE_UART" = "true"
then
cat >> tmp/$PRODUCT-$VERSION/flash-all.bat << EOF
fastboot oem uart disable
EOF
fi
if test "$ERASE_APDP" = "true"
then
cat >> tmp/$PRODUCT-$VERSION/flash-all.bat << EOF
fastboot erase apdp_a
fastboot erase apdp_b
EOF
fi
if test "$ERASE_MSADP" = "true"
then
cat >> tmp/$PRODUCT-$VERSION/flash-all.bat << EOF
fastboot erase msadp_a
fastboot erase msadp_b
EOF
fi
if test "$DISABLE_FIPS" = "true"
then
cat >> tmp/$PRODUCT-$VERSION/flash-all.bat << EOF
fastboot erase fips
EOF
fi
if test "$DISABLE_DPM" = "true"
then
cat >> tmp/$PRODUCT-$VERSION/flash-all.bat << EOF
fastboot erase dpm_a
fastboot erase dpm_b
EOF
fi
cat >> tmp/$PRODUCT-$VERSION/flash-all.bat << EOF
fastboot snapshot-update cancel
fastboot -w --skip-reboot update image-$PRODUCT-$VERSION.zip
fastboot reboot-bootloader
ping -n $SLEEPDURATION 127.0.0.1 >nul

echo Press any key to exit...
pause >nul
exit
EOF

# Create the distributable package
(cd tmp; mv $PRODUCT-$VERSION $PRODUCT-factory-$VERSION; zip -r ../$PRODUCT-factory-$VERSION.zip $PRODUCT-factory-$VERSION)

# Clean up
rm -rf tmp
