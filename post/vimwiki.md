I've started using [Vimwiki][0] recently, mostly for note keeping, and this post is about how
I integrated it into my workflow.

The main feature I use from Vimwiki is the Diary. And the way I've used past note
taking applications were always in short bursts.

 1. Have an idea
 2. Launch the note-taking application
 3. Type in note
 4. Quit application.

As I don't use GVim anymore, to write a note with Vimwiki I
would need an additional "Open Terminal" step in that list. However, I can take
advantage of [Terminator][1]'s profiles for a quicker launch.

> If you're looking for a terminal emulator you can't go wrong with [Terminator][1]. I
particularly enjoy terminal splitting support without needing to use a terminal
multiplexer like screen/tmux.

I've created a new Terminator profile that launches vim with Vimwiki in diary
mode. The profile, as stored in `~/.config/terminator/config`

```ini
[profiles]
  [[vimwiki]]
    icon_bell = False
    background_color = "#300a24"
    cursor_blink = False
    cursor_color = "#aaaaaa"
    font = Inconsolata Medium 12
    foreground_color = "#ffffff"
    show_titlebar = False
    scrollbar_position = hidden
    use_custom_command = True
    custom_command = vim -c VimwikiMakeDiaryNote
    use_system_font = False
```

The most important directives are `use_custom_command` and `custom_command`, but I enjoy
the additional tweaks like hiding the scrollbar, title bar, and whatever visual style I like
right now.


Then I've created a `.desktop` file to customize the appearance, which makes it clear I'm
launching Vimwiki and not another Terminator instance. Source of my
`~/.local/share/applications/vimwiki.desktop`

```ini
[Desktop Entry]
Name=VimWiki
Exec=/usr/bin/kstart --alldesktops /usr/bin/terminator --profile vimwiki --title Vimwiki --geometry 720x600+200+200
Icon=vimwiki
```

 1. `--alldesktops` as the name suggests, Vimwiki will be available on all my
    different desktops (workspaces). I use multiple workspaces when working, so it's quite
    handy that the window follows me around.
 2. `--profile` matches the profile configured in Terminator
 3. `--title` forces the specified title for the newly launched Terminator instance.
    By default, it would be the shell executable path.
 4. `--geometry` allows me to adjust the window dimension and offsets. The default
    Terminator size feels a bit constrictive, which I always end up resizing. Doing
    that every time I want to take a note is a chore.


While Vimwiki seems to have a new logo, it doesn't serve well as an application icon.
Because of that, I've downloaded an older logo that I still found online, and copied it
to `~/.local/share/icons/hicolor/64x64/apps/vimwiki.png`

> Granted the old logo isn't perfect either, as only the WIKI word is readable.



[0]: http://vimwiki.github.io/
[1]: https://terminator-gtk3.readthedocs.io/en/latest/
[2]: https://helpmanual.io/help/kstart/
