Q2 is closing in for the first release of [Rocky Linux], but until that rolls around
I think it might be a good time to give CentOS Stream a try.


While I'm probably one of those users who will jump ship once Rocky Linux
hits the shelves, so to speak, 2021 might not necessarily be the moment I make
the switch. I'm not going to rant about RedHat's current track record; I will say that I somehow managed to trip on a couple of differences between RedHat 8 and CentOS 8.
Which should even exist in the first place. Hopefully, the same issues aren't going to
resurface with Rocky Linux. With the amount of Ansible roles I depend on daily, I'll wait things out a bit to stabilize first.


Anyway. If you like to give Stream a try, AWS at least has official images ready to go.
But if you're on a different cloud provider that doesn't, no need to worry. As long as
they provide CentOS 8 and have cloud-init support (which cloud provider doesn't nowadays?)
you can use the following cloud-init file to switch from CentOS 8 to Stream.

```yaml
#cloud-config
runcmd:
  - dnf install --assumeyes centos-release-stream
  - dnf swap --assumeyes centos-{linux,stream}-repos
  - dnf --assumeyes distro-sync
  - reboot
output : { all : '| tee -a /var/log/cloud-init-output.log' }
```

If you're not familiar with cloud-init, you dump these lines in the cloud-init/user
data field that your cloud provider exposes. Then, on the first machine boot up, cloud-init will run the set of
tasks, and only after will the machine be marked as ready. You can refer to [their documentation][3].
It is quite an extensive configuration format.

Do note that the #cloud-config comment is essential. It defines the format of
the lines to follow (can swap it with a shebang if you want to write a shell script directly).

Additionally, after the reboot, you will want to run a package update. Initially, I had the
update in my set of commands, but DigitalOcean would cut the execution of dnf update,
based on some opaque timeout criteria (?!).

Some providers might already create the /var/log/cloud-init-output.log by default, but better to be explicit. If a cat /etc/*release within the machine still shows CentOS 8
as the release name, refer back to this log file for any runtime issues.




[1]: https://rockylinux.org/
[3]: https://cloudinit.readthedocs.io/en/latest/
