##
## eunuch.kak by wheatdog
## helper for UNIX
##

## TODO:
## sudo-edit
## make sudo "remember" the password

# termcmd should already be set in x11.kak
decl -hidden int _eunuch_cursor_column
decl -hidden int _eunuch_cursor_line
decl -hidden str _eunuch_buffile
decl -hidden str _eunuch_bufname

def -hidden -docstring %{sudo-write : use sudo to write current buffer to disk} \
    sudo-write %{ 
    set current _eunuch_cursor_column %val{cursor_column}
    set current _eunuch_cursor_line %val{cursor_line}
    exec \%
    %sh{
        if [ -z "${kak_opt_termcmd}" ]; then
           echo "echo -color Error 'termcmd option is not set'"
           exit
        fi

        readonly x=$((kak_opt__eunuch_cursor_column - 1))
        readonly y="${kak_opt__eunuch_cursor_line}"

        cmd="printf \"${kak_selection}\" | env SUDO_EDITOR=tee VISUAL=tee sudo -e ${kak_buffile} >/dev/null"
        setsid ${kak_opt_termcmd} "${cmd}" < /dev/null > /dev/null 2>&1
        echo "edit! %val{buffile}"
        printf %s\\n "exec gg ${y}g ${x}l"
    }
}

def -hidden -docstring %{sudo-write-quit : use sudo to write current buffer to disk and quit current client} \
    sudo-write-quit %{ 
    sudo-write
    quit
}

def -hidden -docstring %{sudo-write-quit! : use sudo to write current buffer to disk and quit current client, even if other buffers are not saved} \
    sudo-write-quit! %{ 
    sudo-write
    quit!
}

def -params 1 -file-completion \
    -docstring %{move-file [filename] : move current file to another place. Change current file name and buffer name.} \
    move-file %{ %sh{
        ## only handle two types of absolute path here: 
        ## 1. Expand '~' to users home directory, like "~/a/b/c/file"
        ## 2. Start with '/', like "/etc/file"

        ## check whether new file name is absolute or relative
        if [ "$1" != "${1#/}" ]; then
            newname=$1
        else
            if [ "$1" != "${1#\~}" ]; then
                newname=$(readlink -f ${1/#\~/$HOME})
            else
                newname=$(pwd)/$1
            fi
        fi

        if mv "${kak_buffile}" "${newname}"; then
            echo "echo -color Information \`mv ${kak_buffile} ${newname}\` successed"
        else
            echo "echo -color Error \`mv ${kak_buffile} ${newname}\` failed, see *debug* for more information"
            exit
        fi

        echo "rename-buffer ${newname}"

        ## handle autochdir
        if [ "${kak_opt_autochdir}" == "true" ]; then 
            newdir=$(dirname ${newname})
            echo "cd ${newdir}"
            echo "set buffer working_folder ${newdir}" 
        fi
}}

def -params .. -docstring %{chmod [mode] : change the permission of current file.} \
    chmod %{ %sh{
        if chmod $@ "${kak_buffile}"; then  
            echo "echo -color Information \`chmod $@ ${kak_buffile}\` successed"
        else
            echo "echo -color Error \`chmod $@ ${kak_buffile}\` failed, see *debug* for more information"
        fi
}}

def -docstring %{Print the current working directory} \
    pwd %{ echo %sh{ echo $(pwd) } }

def -docstring %{Delete a buffer and the file on disk simultaneously, even if the buffer is unsaved} \
    remove-file! %{ %sh{ 
        ## check if the buffer is associated with a file
        if [ "${kak_buffile}" != "${kak_bufname}" ]; then 
            if rm "${kak_buffile}"; then
                echo "echo -color Information \`rm ${kak_buffile}\` successed"
                echo "delete-buffer! ${kak_bufname}"
            else
                echo "echo -color Error \`rm ${kak_buffile}\` failed, see *debug* for more information"
            fi
        fi
}}

def -docstring %{Delete a buffer and the file on disk simultaneously} \
    remove-file %{ 
        set current _eunuch_buffile %val{buffile}
        set current _eunuch_bufname %val{bufname}
        delete-buffer %val{bufname}
        %sh{ 
            ## check if the buffer is associated with a file
            if [ "${kak_opt__eunuch_buffile}" != "${kak_opt__eunuch_bufname}" ]; then 
                if rm "${kak_opt__eunuch_bufname}"; then
                    echo "echo -color Information \`rm ${kak_opt__eunuch_buffile}\` successed"
                else
                    echo "echo -color Error \`rm ${kak_opt__eunuch_buffile}\` failed, see *debug* for more information"
                fi
            fi
        }
}

def -docstring %{Remove the file on disk and keep the content inside the buffer, even if the buffer is modified} \
    unlink-file! %{ %sh{ 
        ## check if the buffer is associated with a file
        if [ "${kak_buffile}" != "${kak_bufname}" ] && [ -e "${kak_buffile}" ]; then 
            if rm "${kak_buffile}"; then
                echo "echo -color Information \`rm ${kak_buffile}\` successed"
            else
                echo "echo -color Error \`rm ${kak_buffile}\` failed, see *debug* for more information"
            fi
        fi
}}

def -params .. -file-completion \
    -docstring %{make-directory [<arguments>] : a wrapper for 'mkdir' in shell. 
With no argument, create the containing directory for the current file} \
    make-directory %{ %sh{
        if [ $# -eq 0 ]; then args="-p $(dirname ${kak_buffile})"; else args="$@"; fi

        if mkdir ${args}; then
            echo "echo -color Information \`mkdir ${args}\` successed"
        else
            echo "echo -color Error \`mkdir ${args}\` failed, see *debug* for more information"
        fi
}}

hook global BufCreate .* %{ %sh{
    ## wrap sudo command when 
    ## 1. editing an existed and not writable file
    ## 2. create a file in a privileged directory
    if [ -e "${kak_buffile}" ]; then
        if [ -w "${kak_buffile}" ]; then exit; fi
    else
        dir=$(dirname ${kak_buffile})
        ## if directory is not existed, we don't wrap sudo command
        if [ ! -d "${dir}" ]; then exit; fi
        if [ -w "${dir}" ] && [ -x "${dir}" ]; then exit; fi
    fi

    ## TODO: wa, waq
    printf %s "
    alias buffer w sudo-write
    alias buffer wq sudo-write-quit
    alias buffer wq! sudo-write-quit!
    "
}}

alias global mv move-file
alias global rm! remove-file!
alias global rm remove-file
alias global mkdir make-directory
alias global unlink! unlink-file!
