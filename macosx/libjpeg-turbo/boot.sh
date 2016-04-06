{{ __filename = __filename if package_boot else None }}
{{
	output = "%s-%s" % (package, package_version)
	output += "-%s" % package_release if package_release != "" else ""
}}
#!/bin/bash
set -e -x

apt-get update
apt-get upgrade -y
apt-get install -y git devscripts build-essential yasm automake

{{ =include("../macosx-common.sh") }}

{{
	url = "https://github.com/libjpeg-turbo/libjpeg-turbo/archive"
	version = "master" if package_daily else "%s" % package_version
	download("libjpeg-turbo.tar.gz", "%s/%s.tar.gz" % (url, version), sha)
}}

{{ for (host, arch) in [("i686-apple-darwin12", ""), ("x86_64-apple-darwin12", "64")] }}

su builder -c "mkdir build{{ =arch }}"
cd build{{ =arch }}
su builder -c "tar -xvf ../libjpeg-turbo.tar.gz --strip-components 1"

su builder -c "cat ../*.patch | patch -p1"
su builder -c "autoreconf -i"

su builder -c "./configure --prefix=/usr --host {{ =host }}"
cp config.log /build/config{{ =arch }}.log
su builder -c "make -j3"
su builder -c "mkdir /build/tmp{{ =arch }}"
su builder -c "make install DESTDIR=/build/tmp{{ =arch }}/"
su builder -c "cp -a LICENSE.txt /build/tmp{{ =arch }}/usr/share/doc/libjpeg-turbo"
su builder -c "../fixup-import.py --destdir /build/tmp{{ =arch }} --verbose"

cd ..

{{ endfor }}

su builder -c "(cd /build/tmp; fakeroot tar -cvzf /build/{{ =output }}-osx.tar.gz .)"
su builder -c "./make-universal.py --dir32 /build/tmp --dir64 /build/tmp64"
su builder -c "(cd /build/tmp64; fakeroot tar -cvzf /build/{{ =output }}-osx64.tar.gz .)"
