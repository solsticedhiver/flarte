#!/bin/bash
buildtype=${1:-release}

CWD=`pwd`
rm ./flarte.tar.gz
pushd ..
flutter build linux --${buildtype}
popd
pushd ../build/linux/x64/${buildtype}/bundle
echo ':: making tarball'
tar czf $CWD/flarte.tar.gz ./*
popd

# build flatpak
echo ':: running flatpak-builder'
flatpak-builder --ccache --force-clean build-dir io.github.solsticedhiver.flarte.yml

version=`grep ^version ../pubspec.yaml |cut -f 2 -d ' '|cut -f 1 -d '+'`
sha=`git rev-parse --short main`
rm -f flarte-*.flatpak
# build flatpak single-file bundle
echo ":: making flatpak single-file bundle: flarte-${version}-${sha}-x86_64.flatpak"
flatpak build-export repo.d build-dir
flatpak build-bundle repo.d flarte-${version}-${sha}-x86_64.flatpak io.github.solsticedhiver.flarte

rm -rf repo.d
