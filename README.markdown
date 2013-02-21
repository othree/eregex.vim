# eregex.vim

## Installation

Use [Vundle][] or [pathogen][] is suggested.

[Vundle]:https://github.com/gmarik/vundle
[pathogen]:https://github.com/tpope/vim-pathogen

## Usage

After installed. Just press / or ? for search, it will map to :M command.

You can call EregexToggle funtion to toggle the keymapping. For example, 
add the following line into your .vimrc file:

    nnoremap <leader>/ :call EregexToggle()<CR>

Then you can use <leader>/ to toggle eregex.vim.

For replacement, use :%S// (uppercase S) to use perl style regexp.

## License

Author     : 安久津  
Origin     : [eregex.vim][origin]  
Maintainer : othree  

`:help eregex-license-to-use` for license information.

[origin]:http://www.vector.co.jp/soft/unix/writing/se265654.html
