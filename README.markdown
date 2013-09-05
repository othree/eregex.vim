# eregex.vim

## Installation

Use [Vundle][] or [pathogen][] is suggested.

[Vundle]:https://github.com/gmarik/vundle
[pathogen]:https://github.com/tpope/vim-pathogen

## Quick Start

After installed. Just press / or ? for search, it will map to :M command.

You can call eregex#toggle funtion to toggle the keymapping. For example, 
add the following line into your .vimrc file:

    nnoremap <leader>/ :call eregex#toggle()<CR>

Then you can use  &lt;leader>/ to toggle eregex.vim.

For replacement, use :%S// (uppercase S) to use perl style regexp.

See `:help eregex` for more information.

## Config

Default disable, put this line in vimrc:

    let g:eregex_default_enable = 0

Custom search delimeter:

    let g:eregex_forward_delim = '/'
    let g:eregex_backward_delim = '?'

## Changes

### 2.61

* Support ignorecase

### 2.60

* Support backword search.
* Support count argument.
* Use function to auto map keys.
* Define custom search delimeter.
* hlsearch works fine.

## License

Author     : 安久津  
Origin     : [eregex.vim][origin]  
Maintainer : othree  

`:help eregex-license-to-use` for license information.

[origin]:http://www.vector.co.jp/soft/unix/writing/se265654.html
