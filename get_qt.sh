#!/bin/bash
set -e

USAGE="usage: get_qt.sh [kobo|koboWithDocs|desktop|desktopWithDocs] [stable|experimental] [clean]"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

REPO=https://invent.kde.org/qt/qt/qt5
LOCALREPO_KOBO="${SCRIPT_DIR}/qt-linux-5.15-kde-kobo"
LOCALREPO_DESKTOP="${SCRIPT_DIR}/qt-linux-5.15-kde-desktop"
BRANCH=kde/5.15

PATCH_PATH="${SCRIPT_DIR}/patches/qt5.15.patch"

MODULES_BASE="qtbase qtcharts qtdeclarative qtgraphicaleffects qtimageformats qtnetworkauth qtquickcontrols2 qtsvg qtwebsockets"
MODULES_DOCS="qttools qtdoc"
MODULES_DESKTOP="qttools qttranslations qtx11extras qtwayland"

STABLE_COMMIT="933cb1705c9d8b1d733c719d1cffb8efbec89d7b"

platform=kobo
modules=$MODULES_BASE
localrepo=$LOCALREPO_KOBO
clean=false
stable=false
experimental=false

if [ $# -lt 1 ]
then
	echo "Missing platform argument, defaulting to kobo"
fi
case  ${1:-kobo} in
    kobo)
        platform=kobo
        modules=$MODULES_BASE
        localrepo=$LOCALREPO_KOBO
        ;;
    koboWithDocs)
        platform=kobo
        modules="$MODULES_BASE $MODULES_DOCS"
        localrepo=$LOCALREPO_KOBO
	;;
    desktop)
        platform=desktop
        modules="$MODULES_BASE $MODULES_DESKTOP"
        localrepo=$LOCALREPO_DESKTOP
        ;;
    desktopWithDocs)
        platform=desktop
        modules="$MODULES_BASE $MODULES_DESKTOP $MODULES_DOCS"
        localrepo=$LOCALREPO_DESKTOP
        ;;
    *)
        echo "[!] platform $1 not supported!"
        echo "${USAGE}"
        exit 1
        ;;
esac

while test $# -gt 0
do
    case "$2" in
        clean) clean=true
            ;;
	stable) stable=true
            ;;
        experimental) experimental=true
            ;;
        *)
            ;;
    esac
    shift
done

if [ "$stable" = "$experimental" ]
then
    if [ "$stable" = false ]
    then
        echo "Missing version argument, defaulting to stable"
        stable=true
    else
        echo "[!] Version cannot be stable AND experimental, pick one!"
        exit 1
    fi
fi
if [ "$experimental" = true ]
then
    echo "[.] You are about to get the latest Qt-kde version, shipping like this might break compatibility for other applications using the stable branch."
    read -p "[?] Are you sure ? Press Enter to confirm."
fi

if [ -d "$localrepo" ]
then
    echo "Directory exists. Updating repo..."
    git -C $localrepo pull
else
    git clone --branch $BRANCH $REPO $localrepo
fi

cd $localrepo

if [ "$stable" = true ]
then
  git reset --hard $STABLE_COMMIT
else
  git reset --hard
fi
if [ "$clean" = true ]
then
    git clean -fdx
fi

for mod in $modules; do
    if [ "$stable" = true ]
    then
        git submodule update --init -- $mod
    else
        git submodule update --init --remote -- $mod
    fi
    cd $mod
    git reset --hard
    if [ "$clean" = true ]
    then
        git clean -fdx
    fi
    cd ..
done

git -C qtbase apply --verbose $PATCH_PATH
