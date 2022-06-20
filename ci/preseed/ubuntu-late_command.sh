#!/bin/bash
# Post-install work to be called from the late_command hook in the preseed.
# Doing this here makes it easier to support and maintain.

# constants
target="/target"
apptmp="$target/opt/enLighted/tmp"
installdir="/target/install/"
src="/cdrom/pool/extras/"
# Wrapper around command execution to better-handle logging etc
run_cmd(){
    logfile="/target/var/log/post-install.log"
    echo "run_command :: $@" >> "$logfile"
    $@ >> "$logfile" 2>&1
    [ $? -eq 0 ] || echo "FAILED" >> "$logfile" 2>&1
    # We don't treat failures as fatal. Instead, we try to get as far as we
    # can.
}

# TODO: Find a complete list of expected files, so that we know if one or more
# don't actually get installed.
#run_cmd in-target dpkg -i /cdrom/pool/extras/*.deb

#creat tmp directory

run_cmd mkdir -p "$installdir"
run_cmd mkdir -p "$apptmp"
run_cmd cp "$src/*.deb" "$installdir/"
# directory to take the source files from
tmpsrc="/cdrom/preseed"
tmpfiles="postgresql-client-9.4_9.4.26-0+deb8u1_amd64.deb 1004_ssh_host_dsa_key 1004_ssh_host_dsa_key.pub 1004_ssh_host_rsa_key 1004_ssh_host_rsa_key.pub sshd_config hostname.sh tomcat9.deb psqlpassword.sql firstrun.sh interfaces pg_hba.conf postgresql.conf apache.key apache.pem rewrite_prg.pl etc-bind.bk.tar named.conf.options var-bind.bk.tar setAllEMEnvironment.sh tomcat.conf restore.sh packageupgrade.sh"
run_cmd cp "$tmpsrc"/debian_upgrade.sh /target/opt/enLighted/tmp/debian_upgrade.sh
run_cmd cp "$tmpsrc"/em_all.deb /target/opt/enLighted/tmp/em_all.deb

# Copy one-off files
run_cmd cp "$tmpsrc"/dhcpscript /target/usr/bin/.
run_cmd chmod +x /target/usr/bin/dhcpscript
run_cmd cp "$tmpsrc"/grub /target/etc/default/grub
run_cmd cp "$tmpsrc"/iptables.rules /target/etc/iptables.rules
run_cmd cp "$tmpsrc"/dhcpd.conf /target/etc/dhcp/dhcpd.conf
run_cmd cp "$tmpsrc"/000-default.conf /target/etc/apache2/sites-available/000-default.conf

run_cmd mkdir -p /target/etc/systemd/system/systemd-udevd.service.d
run_cmd cp "$tmpsrc"/systemd-udevd-override.conf /target/etc/systemd/system/systemd-udevd.service.d/override.conf


for srcfile in $tmpfiles; do
    run_cmd cp "$tmpsrc/$srcfile" "$apptmp/"
done

run_cmd cp "$tmpsrc"/finisher.sh /target/root/
run_cmd chroot /target chmod +x /root/finisher.sh
run_cmd chroot /target bash /root/finisher.sh

