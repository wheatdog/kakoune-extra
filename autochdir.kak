##
## autochdir.kak by wheatdog
## Automatically change server's working directory according to the current focus buffer
## To turn on this option, add `set global autochdir true` in your kakrc
##

decl bool autochdir
decl str working_folder

def -hidden \
    autochdir-wrapper %{ %sh{
        if [ "${kak_opt_autochdir}" == "true" ] && [ ! -z "${kak_opt_working_folder}" ] && [ -d "${kak_opt_working_folder}" ]; then
            echo "cd ${kak_opt_working_folder}" 
        fi
} }

def -shell-candidates %{ls -d */} -params ..1 -docstring %{change-directory! [<directory>] : like change-directory, but also update the buffer's working directory} \
    change-directory! %{ %sh{
        echo "cd $@"
    } 
    set buffer working_folder %sh{ echo $(pwd) }
}

hook global BufCreate .* %{
    set buffer working_folder %sh{ 
        if [ "$(basename ${kak_buffile})" == "COMMIT_EDITMSG" ]; then
            echo $(git rev-parse --show-toplevel)
        else
            echo $(dirname ${kak_buffile}) 
        fi 
    }
    autochdir-wrapper
}

hook global WinDisplay .* %{ autochdir-wrapper }
hook global FocusIn .* %{ autochdir-wrapper }

alias global cd! change-directory!
