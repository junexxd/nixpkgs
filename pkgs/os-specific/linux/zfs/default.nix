{ stdenv, fetchurl, kernel, spl, perl, autoconf, automake, libtool, zlib, libuuid, coreutils, utillinux }:

stdenv.mkDerivation {
  name = "zfs-0.6.0-rc13-${kernel.version}";

  src = fetchurl {
    url = http://zfsonlinux.org/downloads/0.6.0-rc13/zfs-0.6.0-rc13.tar.gz;
    sha256 = "1kpx7sa49ir93kmlrjwjzd6v4kzmda4j9cf6bv2p4s3yrmiz3cjv";
  };

  patches = [ ./module_perm_prefix.patch ./mount_zfs_prefix.patch ./kerneldir_path.patch ./no_absolute_paths_to_coreutils.patch ];

  buildInputs = [ kernel spl perl autoconf automake libtool zlib libuuid coreutils ];

  # for zdb to get the rpath to libgcc_s, needed for pthread_cancel to work
  NIX_CFLAGS_LINK = "-lgcc_s";
  NIX_CFLAGS_COMPILE = "-I${kernel}/lib/modules/${kernel.modDirVersion}/build/include/generated";

  preConfigure = ''
    ./autogen.sh

    substituteInPlace ./module/zfs/zfs_ctldir.c    --replace "umount -t zfs"     "${utillinux}/bin/umount -t zfs"
    substituteInPlace ./module/zfs/zfs_ctldir.c    --replace "mount -t zfs"      "${utillinux}/bin/mount -t zfs"
    substituteInPlace ./lib/libzfs/libzfs_mount.c  --replace "/bin/umount"       "${utillinux}/bin/umount"
    substituteInPlace ./lib/libzfs/libzfs_mount.c  --replace "/bin/mount"        "${utillinux}/bin/mount"
    substituteInPlace ./udev/rules.d/*             --replace "/lib/udev/vdev_id" "$out/lib/udev/vdev_id"
    substituteInPlace ./cmd/ztest/ztest.c          --replace "/usr/sbin/ztest"   "$out/sbin/ztest"
    substituteInPlace ./cmd/ztest/ztest.c          --replace "/usr/sbin/zdb"     "$out/sbin/zdb"
  '';

  configureFlags = ''
    --with-linux=${kernel}/lib/modules/${kernel.version}/build 
    --with-linux-obj=${kernel}/lib/modules/${kernel.version}/build 
    --with-spl=${spl}/libexec/spl/${kernel.version}
    ${if stdenv.system == "i686-linux"  then "--enable-atomic-spinlocks" else ""}
  '';

  meta = {
    description = "ZFS Filesystem Linux Kernel module";
    longDescription = ''
      ZFS is a filesystem that combines a logical volume manager with a
      Copy-On-Write filesystem with data integrity detection and repair,
      snapshotting, cloning, block devices, deduplication, and more. 
      '';
    homepage = http://zfsonlinux.org/;
    license = stdenv.lib.licenses.cddl;
    platforms = stdenv.lib.platforms.linux;
    maintainers = with stdenv.lib.maintainers; [ jcumming ];
  };
}
