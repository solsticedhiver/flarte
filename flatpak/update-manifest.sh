#/bin/bash
# update flatpak manifest by using flatpak-flutter

#set -e
long_sha=`git rev-parse main`
# modify manifest to use local repo
sed -i '/url:/s|https.*$|file:///home/solstice/prog/dvcs/flarte|' io.github.solsticedhiver.flarte.yml
sed -i "/commit:/s|: .*$|: $long_sha|" io.github.solsticedhiver.flarte.yml

pushd ~/prog/dvcs/flatpak-flutter
echo ":: flatpak-flutter #1: generate flatpak-flutter.yml"
rm -f flatpak-flutter.yml
uv run flatpak-flutter.py --template file:///home/solstice/prog/dvcs/flarte/ --id io.github.solsticedhiver.flarte --command flarte flatpak-flutter.yml
# use the git source for final manifest
sed -i '/url:/s|file:///home/solstice/prog/dvcs/flarte.git|https://github.com/solsticedhiver/flarte.git|' flatpak-flutter.yml
# just use our latest version of flutter
flutter_version=`cat ~/Applications/flutter/.dart_tool/version`
sed -i "/tag:/s|: .*$|: ${flutter_version}|" flatpak-flutter.yml
echo ":: flatpak-flutter #2: generate final yml"
# add missing finish-args
#sed -i "/dri/a\  - --socket=pulseaudio\\
#  - --share=network" flatpak-flutter.yml
# add missing  install commands
#sed -i "/\/app\/bin\/data/a\      - install -Dm0644 flatpak/io.github.solsticedhiver.flarte.png /app/share/icons/hicolor/256x256/apps/io.github.solsticedhiver.flarte.png\\
#      - install -Dm0644 flatpak/io.github.solsticedhiver.flarte.desktop /app/share/applications/io.github.solsticedhiver.flarte.desktop\\
#      - install -Dm0644 flatpak/io.github.solsticedhiver.flarte.metainfo.xml /app/share/metainfo/io.github.solsticedhiver.flarte.metainfo.xml" flatpak-flutter.yml
rm io.github.solsticedhiver.flarte.yml
uv run flatpak-flutter.py flatpak-flutter.yml
sed -i 's|file:///home/solstice/prog/dvcs/flarte/.git|https://github.com/solsticedhiver/flarte.git|' io.github.solsticedhiver.flarte.yml
# add snippet about latest commit
sed -i '/build-commands/a\      # update commit version to latest HEAD\
      - |\
        commit=`git rev-parse --short HEAD`\
        sed -i "/.*commit/s/HEAD/$commit/" lib/config.dart'  io.github.solsticedhiver.flarte.yml
popd

mv ~/prog/dvcs/flatpak-flutter/io.github.solsticedhiver.flarte.yml .
rm -rf generated
mv ~/prog/dvcs/flatpak-flutter/generated .
