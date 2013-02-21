# eregex.vim

## Installation

Use [Vundle][] or [pathogen][] is suggested.

[Vundle]:https://github.com/gmarik/vundle
[pathogen]:https://github.com/tpope/vim-pathogen

## Usage

Add the following three lines to your vimrc file.

    nnoremap <expr> / ":<C-U>".v:count1."M/"
    nnoremap <expr> ? ":<C-U>".v:count1."M?"
    nnoremap ,/ /
    nnoremap .? ? 

Now you can use / to find. :%S// (uppercase S) to replace.
You can use ,/ to use the origin / .

## License

Author     : 安久津  
Origin     : [eregex.vim][origin]  
Maintainer : othree  

`:help eregex-license-to-use` for license information.

[origin]:http://www.vector.co.jp/soft/unix/writing/se265654.html
