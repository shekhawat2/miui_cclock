#!/usr/bin/bash

LOCALDIR=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`
tools=$LOCALDIR/tools
apktool=$tools/apktool

NAME=$(git log -1 --pretty=%B)

if [ ! -f MiuiSystemUI.apk ]; then
    echo "No Input"
    exit 0
fi

#$apktool empty-framework-dir
$apktool if $LOCALDIR/framework/framework-res.apk
$apktool if $LOCALDIR/framework/framework-ext-res.apk
$apktool if $LOCALDIR/framework/miui.apk
$apktool if $LOCALDIR/framework/miuisystem.apk

echo "Creating Centre Clock Disabler"
rm -rf  $LOCALDIR/flashable/system/priv-app/MiuiSystemUI
mkdir -p $LOCALDIR/flashable/system/priv-app/MiuiSystemUI
cp $LOCALDIR/MiuiSystemUI.apk $LOCALDIR/flashable/system/priv-app/MiuiSystemUI/MiuiSystemUI.apk
#unzip -o $LOCALDIR/flashable/system/priv-app/MiuiSystemUI/MiuiSystemUI.apk META-INF/*
cd $LOCALDIR/flashable
zip $LOCALDIR/$NAME-CentreClockDisabler.zip -r *
cd $LOCALDIR

echo "Decompiling"
$apktool d -s $LOCALDIR/MiuiSystemUI.apk
rm $LOCALDIR/MiuiSystemUI.apk
patch -p1 < lcclock || exit 1
echo "Recompiling"
$apktool b $LOCALDIR/MiuiSystemUI
rm -rf  $LOCALDIR/flashable/system/priv-app/MiuiSystemUI
mkdir -p $LOCALDIR/flashable/system/priv-app/MiuiSystemUI
#cp $LOCALDIR/MiuiSystemUI/dist/MiuiSystemUI.apk $LOCALDIR/flashable/system/priv-app/MiuiSystemUI/MiuiSystemUI.apk
java -jar $tools/signapk/signapk.jar $tools/keys/platform.x509.pem tools/keys/platform.pk8 "$LOCALDIR/MiuiSystemUI/dist/MiuiSystemUI.apk" "$LOCALDIR/flashable/system/priv-app/MiuiSystemUI/MiuiSystemUI.apk"
#zip -ur $LOCALDIR/flashable/system/priv-app/MiuiSystemUI/MiuiSystemUI.apk META-INF
cd $LOCALDIR/flashable
zip $LOCALDIR/$NAME-CentreClockEnabler.zip -r *
cd $LOCALDIR
rm -rf temp

tg_upload() {
    local FILE; FILE=${1}; shift

    if [[ ! -f ${FILE} ]]; then
        echo "tg_upload() failed to find ${FILE}!"
        return 1
    fi

    curl -s -F chat_id="${CHAT_ID}" \
            -F document=@"${FILE}" \
            -F caption="${*}" \
            -X POST https://api.telegram.org/bot"${BOT_TOKEN}"/sendDocument 1>/dev/null
}

tg_upload $LOCALDIR/$NAME-CentreClockEnabler.zip
tg_upload $LOCALDIR/$NAME-CentreClockDisabler.zip
