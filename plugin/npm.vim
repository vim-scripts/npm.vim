" File: npm.vim
" Description: Tab completion for NPM commands.
" Author: Thomas Allen <thomas@oinksoft.com>
" Version: 0.1.1

" Copyright (c) 2013 Oinksoft <https://oinksoft.com/>
" 
" Permission is hereby granted, free of charge, to any person obtaining a
" copy of this software and associated documentation files (the
" "Software"), to deal in the Software without restriction, including
" without limitation the rights to use, copy, modify, merge, publish,
" distribute, sublicense, and/or sell copies of the Software, and to
" permit persons to whom the Software is furnished to do so, subject to
" the following conditions:
" 
" The above copyright notice and this permission notice shall be included
" in all copies or substantial portions of the Software.
" 
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
" OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
" MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
" IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
" CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
" TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
" SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

if exists('g:npm_loaded')
  finish
endif

let g:npm_loaded = 1

" Settings

" If set to non-zero, runs all commands in background (so you lose their
" output).
let g:npm_background = 0

" If some NPM commands aren't being picked up, add them with this list.
let g:npm_custom_commands = []

function! g:npm(...)
  if len(a:000)
    call s:npm_command(a:000[0], a:000[1:])
  else
    call s:npm_command('help', [])
  end
endfunction

function! s:npm_command(cmd, args)
  let cmd = join(['npm', a:cmd] + map(a:args, 'shellescape(v:val)'), ' ')
  let out = system(cmd)
  if ! g:npm_background
    echo out
  endif
endfunction

function! g:npm_complete(arg_lead, cmd_lead, cursor_pos)
  if !exists('g:npm_commands')
    let g:npm_commands = s:load_npm_commands()
  endif
  let commands = copy(g:npm_commands + g:npm_custom_commands)
  return filter(commands, 'v:val =~ "^' . a:arg_lead . '"')
endfunction

function! s:load_npm_commands()
  let npm_help = system('npm help')
  if v:shell_error != 0
    " Report an error here?
    return []
  else
    " This is so much simpler with sed :^(
    let lines = []
    let in_commands = 0
    for line in split(npm_help, '\n')
      if line =~ '^where <command>'
        let in_commands = 1
      elseif in_commands
        if line =~ '^$'
          break
        endif
        call add(lines, line)
      endif
    endfor
    let joined = join(map(lines, 'substitute(v:val, ",", "\n", "g")'), "\n")
    return filter(
          \map(split(joined, "\n"),
            \'substitute('
              \.'substitute(v:val, "^\\s\\+", "", "g"),'
              \.'"\\s\\+$", "", "g")'),
          \'v:val != ""')
  endif
endfunction

" Usage: :Npm <command> [args...]
command! -complete=customlist,g:npm_complete -nargs=* Npm :call g:npm(<f-args>)
