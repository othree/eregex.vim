# eregex.vim

## Installation

Vimball package will not release until English doc is ready.
Now you can clone this repo and use [vim-makefile][] to install.

[vim-makefile]:http://github.com/c9s/vim-makefile

## Usage

Add the following three lines to your vimrc file.

    nnoremap / :M/
    nnoremap ? :M?
    nnoremap ,/ /
    nnoremap ,? ?

Now you can use / to find. :%S// (uppercase S) to replace.
You can use ,/ to use the origin / .

## License

Author     : 安久津  
Origin     : [eregex.vim][origin]  
Maintainer : othree  

Might release under MIT License.

[origin]:http://www.vector.co.jp/soft/unix/writing/se265654.html
