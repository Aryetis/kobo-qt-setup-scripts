```diff
- This fork is based upon Rain92's work and aim to fix, maintain and stabilize its scripts for the foreseeable future
- There is no intention to switch to qt6 at the moment
```

# kobo-qt-setup-scripts

A collection of scripts to setup a development environment for cross compiling Qt apps for Kobo Arm targets.

## Installing the Cross Compiler Toolchain

install_toolchain.sh will install the crosscompiler to the home /home/user/x-tools directory.
It is based on https://github.com/NiLuJe/koxtoolchain, so make sure the necessary dependencies are installed beforehand.
Atfer installing make sure to add the compiler path (/home/${USER}/x-tools/arm-kobo-linux-gnueabihf/bin) to your path variable.

## Installing the Qt dependencies

install_libs.sh [stable|experimental] will download, patch, compile, and install Qt dependencies.
These are: zlib-ng, libb2, zstd, openssl, pnglib, libjpeg-turbo, expat, pcre, libfreetype and harfbuzz.
By default, the stable option will be chosen. Providing frozen version of each of those library so we can all work and ship the same libraries.
Using experimental will get you the latest version of each of those libs but users might have to tinker around and install multiple versions of libraries and qt binaries.

## Downloading and installing Qt
get_qt.sh [kobo|koboWithDocs|desktop|desktopWithDocs] [stable|experimental] [clean] will download the latest repositories of the KDE branch of Qt 5.15.
Targets are eighter kobo or linux desktop. The deskop version will include some additional libraries like for X11 and Wayland.
Using the "WithDocs" version of targets will get you the additional modules necessary to build qt's documentation.
Similary to the install_libs.sh stable will build a qt froze at a specific commit while experimental will get you the latest one (of the kde/5.15 branch)
The clean flag will clean the repositories if they exist already.

build_qt.sh [kobo|desktop] [config] [make] [install] will configure, compile and/or install the previously downloaded Qt version.
The default install directory is /home/${USER}/qt-bin.

deploy_qt.sh will pack the necassary components of the Qt binaries to a single folder so they can be deployed on the the Kobo device.

## Installing a Debugger
install_gdb.sh will download, compile and install both GDB and GDB-Server for debugging.
GDB will be installed in /home/${USER}/x-tools/arm-kobo-linux-gnueabihf/bin.
GDB-Server will be installed in /home/${USER}/x-tools/arm-kobo-linux-gnueabihf/arm-kobo-linux-gnueabihf/sysroot/usr/bin and has to be transfered to deployed on the Kobo device.

## Docker Image
A docker image with complete environment and a preconfigured Qt Creator can be found here https://github.com/Rain92/kobo-qt-dev-docker.
