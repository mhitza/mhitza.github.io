This document was based on my local [GNU Guile][1]-3.0.5 setup. I'm not sure if it works *as is* with an older
version of GNU Guile.

Because of a [dependency in Fedora][2] I had to compile GNU Guile from source release. As such, in your local
setup the paths will differ. This is only relevant when defining the GUILE shell variable, and referencing the
tags file in the vimrc.

> Note that when building GNU Guile from source be sure that you have the readline-devel (or distro equivalent
package) installed. That way the `./configure` step will pick that up, and the `ice-9 readline` module will be
usable.

[Jump to the end](#demo) if you want to see the setup in action.


## System configuration

If you're installing from source, you will want to set the variable `export GUILE=/path/to/guile` explicitly
in your shell rc file (~/.bashrc, ~/.zshrc, etc). The `guild` executable (which I have not used yet), relies
on this variable to detect the executable, as otherwise it defaults to `/usr/local/bin/guile`.


## GNU Guile REPL configuration

When a new REPL instance is started, it will first evalute the contents of your `~/.guile` file. This is where
you customize your REPL. I have currently just two modules enabled.

```scheme
;; Adds all the goodness of GNU readline in the GNU Guile REPL.
;; If you're not familiar already with readline by name alone, it's a C library
;; that allows programs to expose a trully interactive command line, with history,
;; shortcuts, tab completion, etc. Just as if you'd be operating in a common shell.
(use-modules (ice-9 readline))
(activate-readline)


;; Adds colour to the prompt and the result of evaluated s-expressions.
;; While it has no functional impact, it does make the REPL nicer to look at.
;;
;; You will need to download this module from https://gitlab.com/NalaGinrut/guile-colorized
;;
;; I just copied the contents of the colorized.scm file and dropped it in the
;; modules/ice-9/colorized.scm file within the GNU Guile source directory.
;;
;; Alternatively clone the repository and make GNU Guile aware of the new path. E.g
;; (add-to-load-path "/absolute/path/to/guile-colorized-clone")
(use-modules (ice-9 colorized))
(activate-colorized)
```

## Vim integration

As a vim user I had to spend a couple of hours researching different plugins, reddit posts, configurations
and help pages to figure out how to set up a similar environment. I hope this result pops up for fellow
vim users when they embark on the same Scheme journey.

> Note to new vim users, for plugin management I use [Vundle][0]. If you're using another plugin to manage vim
packages be sure to replace the `Plugin` calls.


My annotated `.vimrc` configuration.

```vim
" GNU Guile syntax highlighting
Plugin 'HiPhish/guile.vim'

" The detection works best if it can find the (use-modules) function
" call around the beginning of the file. That won't work for new files.
" As I'm only writing GNU Guile scheme code at this point, I'm alright
" with setting the filetype for all the *.scm files.
autocmd BufRead,BufNewFile *.scm set ft=scheme.guile


" vim-sexp-mappings-for-regular-people and it's dependencies (in reverse
" order). Provides the little conveniences when writing code, like auto
" closing parenthesis, shortcuts for reordering sexpressions and expanding
" /contracting parenthesis left/right (slurpage/burfage (?!))
"
" Right now I have no additional configuration setup for these plugins,
" but in the future I'd like to remap some command to insert mode
" shortcuts.
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-repeat'
Plugin 'guns/vim-sexp'
Plugin 'tpope/vim-sexp-mappings-for-regular-people'


" Colour parenthesis based on their nesting level.
Plugin 'luochen1990/rainbow'

" Disabled by default, and only enabled for .scm files.
let g:rainbow_active = 0
autocmd BufRead,BufNewFile *.scm :RainbowToggleOn


" A plugin that sends the current paragraph, or selected area to a
" configured target.
"
" The first time in a session when you'll want to send something to the
" target (via <Ctrl-C> <Ctrl-C>) it will ask you to point out which
" buffer is the vim terminal
Plugin 'jpalardy/vim-slime'

" Configure slime to target the built in vim terminal. Only works with
" Vim8+ (any up to date distribution at this point, probably).
let g:slime_target = "vimterminal"


" I prefer my interactive REPL as a right side vertial split.
" Just run :GuileTerminal in your vim session to start it and use
" <Ctrl-W> <Ctrl-W> to switch between windows.
"
" Consult the vim `:help terminal` document to get a clear view of how
" vim behaves when you're focus is within the terminal buffer.
command GuileTerminal rightbelow vertical terminal guile

" Load etags file for the builtin GNU Guile modules. Makes it easy to
" use <Ctrl-]> to jump to definitions and <Ctrl-T> to jump back.
"
" To generate the TAGS file I ran make etags within the source directory.
" Not sure if they are generated out of the box for installation using
" distribution packages.
autocmd BufRead,BufNewFile *.scm set tags+=$HOME/.local/binaries/guile-3.0.5/module/TAGS
```

<a name="demo"></a>
---
![sample-integration](https://user-images.githubusercontent.com/273079/107860537-6c621500-6e48-11eb-8baf-ced9777e1c99.gif)


[0]: https://github.com/VundleVim/Vundle.vim
[1]: https://www.gnu.org/software/guile/
[2]: https://bugzilla.redhat.com/show_bug.cgi?id=1828124
