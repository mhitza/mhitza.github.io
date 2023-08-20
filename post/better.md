**A couple of days after hacking out the solution in bash, I realized that I could have skipped the from scratch
approach, and patch a copy of the file module.** Even if I would have thought of this before, I would still have
taken the same path first, but would have had a quick fallback plan. The clean, from scratch solution is desirable
after all.

Copied the source of the [file module][file_module] (exact revision link), and patched it out to always
attempt to create parent directory hierarchy + symlink.

```diff
680,684d679
<     changed = module.set_fs_attributes_if_different(file_args, changed, diff, expand=False)
<     changed |= update_timestamp_for_file(file_args['path'], mtime, atime, diff)
<     if recurse:
<         changed |= recursive_set_attributes(b_path, follow, file_args, mtime, atime)
<
941a937,940
>     module.params['state'] = 'absent' if module.params['state'] == 'absent' else 'link'
>     module.params['force'] = True
>     if module.params['state'] == 'absent':
>         module.params['src'] = None
970,980c969
<     if state == 'file':
<         result = ensure_file_attributes(path, follow, timestamps)
<     elif state == 'directory':
<         result = ensure_directory(path, follow, recurse, timestamps)
<     elif state == 'link':
<         result = ensure_symlink(path, src, follow, force, timestamps)
<     elif state == 'hard':
<         result = ensure_hardlink(path, src, follow, force, timestamps)
<     elif state == 'touch':
<         result = execute_touch(path, follow, timestamps)
<     elif state == 'absent':
---
>     if state == 'absent':
981a971,973
>     else:
>         result = ensure_directory(os.path.dirname(path), follow, recurse, timestamps)
>         result = ensure_symlink(path, src, follow, force, timestamps)
```

> Assuming you have the file.py file copied somewhere locally, and the above diff in a deepsymlink.diff file,
> you can apply the patch using: `patch file.py deepsymlink.diff`
 
The patched version:

 * makes more operational sense than an action plugin, and I'm able to actually test.
 * is dependency free (`jq`) compared to the bash script.




[file_module]: https://raw.githubusercontent.com/ansible/ansible/390e508d27db7a51eece36bb6d9698b63a5b638a/lib/ansible/modules/file.py
