##
## mutt.kak by lenormf
## Highlight temporary mail files at the default location
##

# http://www.mutt.org/
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook global WinCreate /tmp/mutt-.* %{
    set buffer filetype mail
}

