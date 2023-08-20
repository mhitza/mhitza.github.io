## Just have ChatGPT do it for you

I've experimented with both Copilot and ChatGPT when they were released to the public, to get a feel on how
well they work. And ChatGPT has been quite fun on release, when fewer "guardrails" were put in place. However
it's not a tool I use on a daily basis, thus I often even forget to think of it as an option.

While writing this article, I thought that I should give it a quick try, as this task is: small enough,
self-contained, and I don't doubt that Ansible code from somewhere™ got mixed into it's training data.

Quoted is my prompt, and within the section separators will be the verbatim ChatGPT response.

> create a custom Ansible module, that given a src= and a dest= argument, creates a symlink to the absolute path
> of src, at the destination path of dest. If the parent directory of the destination doesn't exist, recursively
> create those directories (a la `mkdir -p`)

--- 

Creating a custom Ansible module involves writing Python code that interacts with Ansible's API. Below is an
example of a custom Ansible module that fulfils the requirements you've described. This module creates a symbolic
link at the specified destination path to the absolute path of the source.

Save the following Python code in a file named **`create_symlink.py`**:

```python
#!/usr/bin/python

from ansible.module_utils.basic import AnsibleModule
import os

def create_symlink(src, dest):
    try:
        os.makedirs(os.path.dirname(dest), exist_ok=True)  # Recursively create parent directories if needed
        os.symlink(os.path.abspath(src), dest)
        return True, None
    except Exception as e:
        return False, str(e)

def main():
    module = AnsibleModule(
        argument_spec=dict(
            src=dict(type='str', required=True),
            dest=dict(type='str', required=True)
        )
    )

    src = module.params['src']
    dest = module.params['dest']

    success, error_msg = create_symlink(src, dest)

    if success:
        module.exit_json(changed=True, msg=f"Symlink created from {src} to {dest}")
    else:
        module.fail_json(msg=f"Failed to create symlink: {error_msg}")

if __name__ == '__main__':
    main()
```

Make the script executable:

```bash
chmod +x create_symlink.py
```

You can now use this script as a custom Ansible module. Here's an example playbook that demonstrates how to
use the module:

```yaml
---
- name: Create Symbolic Link
  hosts: localhost
  tasks:
    - name: Create symlink
      create_symlink:
        src: /path/to/source/file
        dest: /path/to/destination/symlink
      become: yes
```

Replace **`/path/to/source/file`** with the actual source file path and **`/path/to/destination/symlink`** with
the desired destination path for the symlink.

Remember to put the **`create_symlink.py`** script in the same directory as your playbook or specify the full
path to the script in the create_symlink module invocation.

---

A few things to note for the response generated. While I'm sure it doesn't hurt, the executable flag is not
necessary, and neither is the additional shebang. If however the module is going to be executed as a
commandline tool (an example later), I still think in practice the non Python3 explicit shebang can still
cause some runtime errors. Some older distribution that are active still, have the bin path python binary pointed at
Python2 for compatibility with older software.

> Don't quote me on this, as a non-Python developer I haven't kept up to date with what distro does exactly
> what, but I have encountered similar issues when sharing with people the instruction to run `pip`
> commands, when I should have told them instead to use `pip3` due to system defaults.

Another thing to note is that if the sample playbook is created as shown in the example, and the
create_symlink.py file is placed in the same directory it won't get just picked up during execution.

```shell
ls create_symlink.py 
create_symlink.py

ansible-playbook play.yaml
ERROR! couldn't resolve module/action 'create_symlink'. This often indicates a misspelling, missing collection, or incorrect module path.

The error appears to be in '/home/dm/Workspace/personal/workstation/library/play.yaml': line 4, column 7, but may
be elsewhere in the file depending on the exact syntax problem.

The offending line appears to be:

  tasks:
    - name: Create symlink
      ^ here
```

And as ar as the suggestion to "specify the full path to the script in the create_symlink module invocation" I
don't know enough to know if something like that is possible or its just commingling different data it has
about tasks (for example when a command/shell module is used; where other user scripts might be involved).


On the other hand, one of those ChatGPT notes made me curious, since the modules themselves have a main
section, they are obviously callable as programs, so I've fiddle with it's execution until I figured out what
input it expects. Here's how to invoke an Ansible module on the commandline as a program:

```shell
echo '{ "ANSIBLE_MODULE_ARGS": { "src": "main.yaml", "dest": "/tmp/a/b/c/main.yaml" }}' | ./create_symlink.py
```


Excluded in this post, but
I've played around more with ChatGPT, prompting it to refine the code to account for
possible errors, and restarted the prompt to have it present alternative implementations. Each of those
had some minor gotcha, but overall I could have used them for a baseline from-scratch
implementation and tack on the additional features the patched code just supports (file attributes, selinux
contexts, for example).
