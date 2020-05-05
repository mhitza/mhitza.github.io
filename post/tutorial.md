In the last few months, I had to write multiple Ansible playbooks, to the point that the
slow write/test cycle became a major annoyance. What seemed to work well for me was a mix between
Ansible tags and Vagrant snapshots. I would be happy to hear what workflow others employ, that
specifically minimizes the time they spend testing.

## Setup

`Vagrantfile`
```ruby
Vagrant.configure("2") do |config|
  # As a Fedora user I tend to use CentOS for my VMs, as the knowledge accrued in one
  # system translates to knowledge in RedHat/CentOS. Ideally I would use Fedora server all
  # the time, but I don't want to impose my preference for a less mainstream server
  # distribution onto my clients.
  #
  # Just using CentOS is enough, as the package manager, default configuration paths and
  # SELinux work exactly like within Fedora.
  config.vm.box = "centos/8"


  # While this section isn't strictly required, as we will be running Ansible playbook manually,
  # I like to include it as it simplifies sharing of the proof of concept. Other users can test
  # setup later on with a single vagrant up.
  #
  # While on the topic of sharing, if you're creating a development environment that uses Vagrant
  # and Ansible, I highly recommend ansible_local[1]. That way developers don't need to have Ansible
  # installed locally to bootstrap the box.
  config.vm.provision "ansible" do |ansible|
    ansible.playbook           = "playbook.yml"
    ansible.compatibility_mode = "2.0"
    ansible.inventory_path     = "inventory.ini"
    ansible.limit              = "vagrant"
  end
end
```

`inventory.ini`
```ini
# Instead of a static ini file it's worth considering writing a shell script[2]. As with multiple
# vagrant machines up at the same time the ansible_ssh_port will differ. Also worth considering
# is that with certain VMs the ansible_private_key_file might be located someplace else.
#
# The reliable source of ssh configuration parameters can be extracted from the output of
# vagrant ssh-config
#
# Worth noting that there's also the convenience of setting StrictHostKeyChecking=no inside the
# inventory file. If you're not familiar, ssh creates a fingerprint for each host:port it connects
# to (stored in ~/.ssh/known_hosts), and that information differs between vagrant VMs.
# With this flag we bypass the check that would prevent us to connect to our vagrant VM.
[vagrant]
127.0.0.1 ansible_ssh_port=2222 ansible_user=vagrant ansible_private_key_file=".vagrant/machines/default/virtualbox/private_key" ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```


`playbook.yml`
```yaml
- hosts: all
  become: yes
  tasks:
    # I use this step to ensure every package I depend on or use is installed inside the VM.
    # Even if some things work out of the box with the Vagrant VM, cloud versions of the same
    # distributions will have a smaller subset of packages installed. This way I cover all bases
    - include_tasks: tasks/setup-system.yml
      tags: ['system']

    # I use the cleanup step to remove any temporary files/directories/utilities that are
    # required during configuration but not on the running system. Most of the time this set of
    # tasks is omitted, but if I'm generating a custom cloud image via Packer this set of tasks
    # are more likely to be present
    - include_tasks: tasks/cleanup-system.yml
      tags: ['system']

- hosts: vagrant
  # Most of the time I use this section to install tools to help me debug configuration issues.
  # vim, netstat, selinux related command line utilities, etc
```


## Workflow

Since I'm using CentOS most of the time, the first few tasks inside `tasks/setup-system.yml` will be
for enabling additional repositories like EPEL and Remi. Then I spin up the VM and create the first
  snapshot.

```shell
$ vagrant up
...
$ vagrant snapshot save default system
==> default: Snapshotting the machine as 'system'...
==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using `vagrant snapshot restore`. You can delete it using
==> default: `vagrant snapshot delete`.
```

At this point I can start hacking on the configuration tasks following the same approach presented
for system setup and cleanup.

**What's important to note here**, and non-intuitive for me, is that you
  want to use the `--skip-tags` Ansible flag, instead of `--tags`. Given the example playbook if we
  were to run `ansible-playbook -i inventory --tags 'system' playbook.yml` none of the tasks defined
  in `tasks/setup-system.yml` will run.

```shell
$ ansible-playbook -i inventory --tags 'system' playbook.yml

PLAY [all] **************************************************************************************

TASK [Gathering Facts] **************************************************************************
ok: [127.0.0.1]

TASK [include_tasks] ****************************************************************************
included: /home/user/folder/tasks/setup-system.yml for 127.0.0.1

PLAY RECAP **************************************************************************************
127.0.0.1 : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

The reason is that with the `--tags` flag Ansible will run only the tasks explicitly marked with the
specific tags, even if a top level `include_tasks`/`include_role` is marked with the tag, all the
tasks within that file need to be also marked with the tag.

In our hypotethical example then, I'll run the playbook with the `--skip-tags` argument which in my
opinion works intuitively.

```shell
$ ansible-playbook -i inventory.ini --skip-tags 'all,the,other,tags' playbook.yml 

PLAY [all] **************************************************************************************

TASK [Gathering Facts] **************************************************************************
ok: [127.0.0.1]

TASK [include_tasks] ****************************************************************************
included: /home/user/folder/tasks/setup-system.yml for 127.0.0.1

TASK [System - install EPEL repository] *********************************************************

TASK [geerlingguy.repo-epel : Check if EPEL repo is already configured.] ************************
ok: [127.0.0.1]

TASK [geerlingguy.repo-epel : Install EPEL repo.] ***********************************************
skipping: [127.0.0.1]

TASK [geerlingguy.repo-epel : Import EPEL GPG key.] *********************************************
skipping: [127.0.0.1]
...
```

Once I'm pleased with the setup for one component of the system (webserver, database, etc), I'll
restore my "system" snapshot, run Ansible only with the new section (with the appropriate
`--skip-tags`) preferably twice and ensure nothing `changed`.

```shell
$ vagrant snapshot restore default system --no-provision
```

If all seems to work well, I then might create a new snapshot that includes the newly configured
component and reiterate on the process.


---
Sometimes I include tags inside my tasks/\*.yml files as well. For example, I might have a
step that interacts with an API that has rate limits, or package manager installs that add
undesired latency to my flow. For those scenarios I use a generic 'skip' tag.


[1] https://www.vagrantup.com/docs/provisioning/ansible_local.html

[2] https://docs.ansible.com/ansible/latest/user_guide/intro_dynamic_inventory.html
