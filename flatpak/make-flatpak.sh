#!/bin/bash
# build a flatpak from local repo

set -e
#version=`grep ^version ../pubspec.yaml |cut -f 2 -d ' '|cut -f 1 -d '+'`
sha=`git rev-parse --short main`
long_sha=`git rev-parse main`

# modify manifest to build local repo
sed -i '/url:/s|https.*flarte.*$|file:///home/solstice/prog/dvcs/flarte|' io.github.solsticedhiver.flarte.yml
sed -i "/commit:/s|: .*$|: $long_sha|" io.github.solsticedhiver.flarte.yml

# build flatpak
echo ':: running flatpak-builder'
flatpak-builder --force-clean --repo=repo.d build.d io.github.solsticedhiver.flarte.yml

rm -f flarte-*.flatpak
# check for llvm22 extension
if ! flatpak list |grep -q org.freedesktop.Sdk.Extension.llvm22 ;then
	flatpak install --user org.freedesktop.Sdk.Extension.llvm22
fi
# build flatpak single-file bundle
echo ":: making flatpak single-file bundle: flarte-${sha}-x86_64.flatpak"
flatpak build-bundle repo.d flarte-${sha}-x86_64.flatpak io.github.solsticedhiver.flarte

# restore manifest
git restore io.github.solsticedhiver.flarte.yml
rm -rf repo.d
rm -rf build.d
