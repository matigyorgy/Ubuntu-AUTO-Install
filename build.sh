#!/bin/bash

WORKDIR=temp
rm -rf $WORKDIR
mkdir $WORKDIR

ISO_FILES=default
mkdir -p $ISO_FILES

##### [Copy ISO file default directory ] #####
cp -r ./$ISO_FILES/*.iso .

ISO_COUNT=$( find -name '*.iso' | grep -v AUTO | wc -l )
for (( i=1 ; ((i-$ISO_COUNT)) ; i=(($i+1)) ))
do
	#####[ Building name of new iso ]#####
	ISO_SRC=$( find -name '*.iso' | grep -v AUTO | head -n 1 )
	ISO_PREFIX=$( echo "$ISO_SRC" | sed 's/.iso//' )
	ISO_TARGET=$( echo "$ISO_PREFIX-AUTO.iso" )
	#####[ Extracting files from iso ]#####
	xorriso -osirrox on -dev $ISO_SRC \
		-extract "/isolinux/isolinux.cfg" $WORKDIR/isolinux.cfg \
		-extract "/md5sum.txt" $WORKDIR/md5sum.txt
	#####[ Adding preseed to initrd ]#####
	cp ks.preseed $WORKDIR/
	cp ks.cfg $WORKDIR/
	cd $WORKDIR
	gunzip initrd.gz
	chmod +w initrd
	echo "ks.preseed" | cpio -o -H newc -A -F initrd
	gzip initrd

	#####[ Changing default boot menu timeout ]#####
	sed -i 's/timeout 0/timeout 1/' isolinux.cfg
	echo en > lang

	#####[ Changing default boot menu]#####
	cat > isolinux.cfg <<- EOF
	default install
	label install
		menu label ^Install Ubuntu Server AUTO
		kernel /install/vmlinuz
		append file=/cdrom/preseed/ubuntu-server.seed initrd=/install/initrd.gz ks=cdrom:/ks.cfg preseed/file=/cdrom/ks.preseed --
	EOF

	#####[ Fixing MD5 ]#####
	fixSum isolinux.cfg ./isolinux/isolinux.cfg
	fixSum ks.cfg ./ks.cfg
	fixSum ks.preseed ./ks.preseed
	cd ..

	#####[ Writing new iso ]#####
	rm $ISO_TARGET
	xorriso -indev $ISO_SRC \
		-map  $WORKDIR/isolinux.cfg "/isolinux/isolinux.cfg" \
		-map  $WORKDIR/ks.cfg "/ks.cfg" \
		-map  $WORKDIR/md5sum.txt "/md5sum.txt" \
		-map  $WORKDIR/ks.preseed "/ks.preseed" \
		-boot_image isolinux dir=/isolinux \
		-outdev $ISO_TARGET

	rm -rf $WORKDIR
	rm $ISO_SRC
done
#xorriso
