##
## clearsilver.kak by lenormf
##

# http://www.clearsilver.net/
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

# Detection
# ‾‾‾‾‾‾‾‾‾

hook global BufCreate .+\.cst %{
    set buffer filetype clearsilver
}

hook global WinSetOption mimetype=text/html %{
    %sh{
        ## If the file is detected as a python or shell script, reset the filetype
        ## This occurs because clearsilver files contain HTML markup
        if echo "cst" | grep -qiw "${kak_bufname##*.}"; then
            echo "set buffer filetype clearsilver"
        fi
    }
}

# Highlighters
# ‾‾‾‾‾‾‾‾‾‾‾‾

addhl -group / regions -default code clearsilver \
    inline_cs '<\?cs' '\?>' ''

addhl -group /clearsilver/code ref html

addhl -group /clearsilver/inline_cs regions content \
    string '"' (?<!\\)(\\\\)*"      '' \
    string "'" "'"                  ''

addhl -group /clearsilver/inline_cs/content/string fill string

addhl -group /clearsilver/inline_cs regex '(<\?cs)|(\?>)' 0:magenta
addhl -group /clearsilver/inline_cs regex \b[+-]?(0x\w+|#?\d+)\b 0:value
addhl -group /clearsilver/inline_cs regex (subcount|name|first|last|abs|max|min|string.slice|string.find|string.length|_)\( 1:keyword
addhl -group /clearsilver/inline_cs regex (var|evar|lvar|include|linclude|set|name|if|else|elif|alt|each|loop|with|def|call): 1:attribute
addhl -group /clearsilver/inline_cs regex /if 0:attribute

# Commands
# ‾‾‾‾‾‾‾‾

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook global WinSetOption filetype=clearsilver %{
    addhl ref clearsilver
}
hook global WinSetOption filetype=(?!clearsilver).* %{
    rmhl clearsilver
}
