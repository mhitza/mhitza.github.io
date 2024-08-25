There is no background ssh-agent by default in the default desktop session.

To fix this, I've written the following script to `$HOME/.config/plasma-workspace/env/ssh-agent.sh`

```shell
#
# Thanks Josue for the insight:
#   https://dev.to/manekenpix/kde-plasma-ssh-keys-111e
#

[ -z "$SSH_AGENT_PID" ] && eval "$(ssh-agent -s)"
```

> All files stored under $HOME/.config/plasma-workspaces/env are automatically sourced at session startup.
