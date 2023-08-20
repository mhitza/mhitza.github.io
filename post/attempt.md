In the past few days I've been typing away at some Ansible automation for my local system, and when dealing
with dotfile symlinks, I have the following group of tasks:

```yaml
- name: "absolute home {{ config_path }}"
  set_fact:
    absolute_home_config_path: "{{ user_home_dir + '/.' + config_path }}"

- name: "{{ absolute_home_config_path|dirname }} present"
  file:
    dest: "{{ absolute_home_config_path|dirname }}"
    state: directory
  become_user: "{{ username }}"

- name: "{{ config_name }}"
  file:
    src: "{{ playbook_dir }}/files/home/{{ config_path }}"
    dest: "{{ absolute_home_config_path }}"
    state: link
    force: true
    mode: "{{ config_mode if config_mode is defined else '0600' }}"
```

The short description of this group of tasks would be, to symlink a desired source file (within my playbook
directory) to a specific location within my home directory, while ensuring the directory path down to my symlink
exists. With htoprc as an example, the shell script translation for the task at hand would be:

```shell
mkdir --parents ~/.config/htop
ln --force --symbolic files/home/config/htop/htoprc ~/.config/htop/htoprc
```

While I don't mind the extra verboseness of the tasks - a trade-off I'm fine with for the extra properties Ansible
has to offer (such as idempotence) - when I run the playbook, the output feels rather cluttered for this
specific project. It would be nice if the `ansible.builtin.file` module would be able to do this out of the
box, but as things stand I went looking for alternatives.

---

My first attempt was to look out for a specific [callback plugin][cb_plugin] that would get me there quickly.
The one that came closest to what I've been trying to do was the [selective plugin][s_plugin]. This plugin
would have me tag with 'print_action' each task that I want to show in the output. Since the majority of the
tasks are of interest, and only a handful that I'd like to ignore, seemed that I'd just clutter more my
playbooks. Instead of going with the sensible approach, take the extra hit with a few more lines that get
copy-pasted around, I set out to write a module that does what I'd like the builtin file module would support.


While I've been writing Ansible playbooks for multiple projects and deployments, going as far back as 2013, I
never felt the need to reach out to custom module development. At most, I'd find an external module, or plugin, in a
public repository somewhere and integrate it within the projects. I know *some* Python, Ansible is well
established, plentiful of examples out there, how hard could it be? Right? Right?

I was expecting to write something quick and dirty based on the existing code I could find out there.


## Developing a custom Ansible module

First I wanted to get some reference code or tutorial on the topic. Helpfully, the
official documentation has a introductory page about "[Developing modules][dev_modules]".

After copying the example code into a Python script, which I've named `deepsymlink.py`, in a new `./library/` folder
within my project, I was able to invoke the module:

```shell
ANSIBLE_LIBRARY=./library ansible -m deepsymlink -a "name=hello new=true" localhost
```

> Arguments passed in via the `-a` flag are those found in the example code. At this point the only 
> difference from the example code was the script filename.

"Great, now I just have to find the file module code", thinking that I can just copy/paste the code paths
I'm interested in, effectively merging the symlinking procedure with the one that recursively creates directories.

> The file module, via the `state` parameter has various behaviours. With the `link` value it will create a
> symlink, and with the `directory` value it will create the desired directory and all it's parents along the
> way.


> By coincidence, this was also the day in which - after seeing it praised many times on HN - I've signed
> up for a Kagi search trial. While I mostly use a mix of Google and DuckDuckGo, I wanted to see how it fares in
> comparison for development work. An unplanned review, if you will.

The builtin [file.py][file_py] is a 987 line Python script, with ~220 lines of documentation strings,
used in the generation of official docs. Not terribly big. However, it became apparent from the start, 
the patterns used within diverge visibly from the boilerplate code.

After about half an hour of going through some cycles of code deletion, imports juggling, and reexecution of
on the commandline I didn't feel like I was making progress.

### "Can I make a module, which calls other modules?"

[The answer to that questions seems to be no.][so_answer]

Based on Konstantin Suvorov's StackOverflow answer, modules must be self-contained, as their are run in isolation from
one another on a remote host.  Couple things I didn't check at the time:

 * are these module restrictions mentioned anywhere in the official documentation?
 * if I'm running the tasks locally (`connection: local`), i.e. no remote server involved, can I "cheat" and
   access the other modules?


## Developing a custom Ansible ~module~ plugin

Starting from the example posted in the StackOverflow answer, I quickly type out the following code.

```python
from ansible.plugins.action import ActionBase

class ActionModule(ActionBase):
    def run(self, tmp=None, task_vars=None):
        result = super(ActionModule, self).run(tmp, task_vars)

        print(self._task.args.get('src'))
        print(self._task.args.get('dest'))
        pass
```

First impression, "This seems less boilerplate-y. I like it!". Then when it came to testing this plugin, it
didn't seem as straightforward. First, while skimming the [documentation page][doc_plugins] - this time around -, I didn't notice
the fact that action plugins need to be named after a module which they "augment". This became apparent when I
looked over the [bundled action plugins][bap], recognizing some of those files as module names as well.

Renamed my plugin to `file.py` and tried to execute the file module hoping to see the extra outputs:

```shell
ANSIBLE_LIBRARY=./library ansible -m file -a "src=main.yaml dest=/tmp/main.yaml state=link" localhost
localhost | FAILED! => {
    "msg": "module (file) is missing interpreter line"
}
```

This specific error, based on [reports I've seen on GitHub][missing_interpreter] can be caused by a variety of
circumstances where there's some name overlap between various files, playbooks, etc. In my case, similar to
one commenter, and which seemed the most sensible answer based on the error message, was to add a Python
shebang to my script (`#!/usr/bin/env python3`). I'm not sure why this was necessary, as plugins can only be
written in Python and none of the bundled plugins seem to have a shebang line.

While this progressed the execution further, it wasn't outputting anything:

```shell
localhost | FAILED! => {
    "changed": false,
    "module_stderr": "",
    "module_stdout": "",
    "msg": "MODULE FAILURE\nSee stdout/stderr for the exact error",
    "rc": 0
}
```

After giving it a try with `-vvvvvv`, "very"x5 verbose flag I still got nothing. I've also attempted to use
some Display class, as I've seen within another plugin, but in the end it made no difference.


At this moment, I felt that I went too deep down this path. Took a break, and zoomed out a bit. Since
Ansible modules can be written in any language that can run on a system, bash is generally a given on the
system I'm targeting with this automation.


## When in doubt, "bash" it out

Quickly found a [well written guide on how to write Ansible modules in bash][bash_ansible_module], took a
refresher on [how to use jq to create objects without heavy string interpolation][jq_object] (or excessive quotation
escapes), and wrote the following `deepsymlink` script:

```shell
#!/usr/bin/env bash

# $1 - file that contains module arguments key=value pairs on separate lines
source "$1" 
changed=0

alias json="jq --null-input '\$ARGS.named'"

if [ ! -f "$src" ]; then
  json --arg msg "src=$src not found" --argjson failed 'true'
  exit 1
fi

realsrc=$(realpath "$src")

parent=$(dirname "$dest")

if [ ! -d "$parent" ]; then
  mkdir -p "$parent"
  changed=1
fi

if [ ! -L "$dest" ]; then
  ln -f -s "$realsrc" "$dest"
  changed=1
else 
  target=$(readlink -f "$dest")
  if [ "$realsrc" != "$target" ]; then
    ln -f -s "$realsrc" "$dest"
    changed=1
  fi
fi

json --argjson changed "$changed"
```

Got hit by a `bash: json: command not found`, totally forgot that aliases aren't expanded by default when a
shell script are executed in a non-interactive environment. Quick search for a [StackOverflow answer][so_shopt], I need
to set `shopt -s expand_aliases` somewhere within my bash script before the `json` alias is used.

```shell
ANSIBLE_LIBRARY=./library ansible -m deepsymlink -a 'src=main.yaml dest=/tmp/a/b/cx/y/z/.main.yaml' localhost
localhost | CHANGED => {
    "changed": 1
}

ANSIBLE_LIBRARY=./library ansible -m deepsymlink -a 'src=main.yaml dest=/tmp/a/b/cx/y/z/.main.yaml' localhost
localhost | SUCCESS => {
    "changed": 0
}
```

Good enough, and as a compromise I was fine with having `jq` as a dependency on my system (or target systems)
for the shell script to reliably work. *I'll find a better solution next time*


[cb_plugin]: https://docs.ansible.com/ansible/latest/collections/index_callback.html
[s_plugin]: https://docs.ansible.com/ansible/latest/collections/community/general/selective_callback.html#ansible-collections-community-general-selective-callback
[dev_modules]: https://docs.ansible.com/ansible/latest/dev_guide/developing_modules_general.html
[file_py]: https://github.com/ansible/ansible/blob/devel/lib/ansible/modules/file.py
[so_answer]: https://stackoverflow.com/questions/46893066/calling-an-ansible-module-from-another-ansible-module
[doc_plugins]: https://docs.ansible.com/ansible/latest/dev_guide/developing_plugins.html
[bap]: https://github.com/ansible/ansible/tree/devel/lib/ansible/plugins/action
[missing_interpreter]: https://github.com/ansible/ansible/issues/40561
[bash_ansible_module]: https://github.com/pmarkham/writing-ansible-modules-in-bash/blob/master/ansible_bash_modules.md
[jq_object]: https://unix.stackexchange.com/questions/676634/creating-a-nested-json-file-from-variables-using-jq
[so_shopt]: https://stackoverflow.com/questions/33135897/bash-alias-command-not-found
