# Disable file completions for goenv arguments.
complete -c goenv -f

# Subcommands offered before a command is selected.
set -l _bwgoenv_cmds use install uninstall list list-remote help
set -a _bwgoenv_cmds -use --use -install --install -uninstall --uninstall -list --list \
    -list-remote --list-remote -help --help

# List installed versions and their major.minor shorthands.
function _bwgoenv_installed_versions
    set -l root "$HOME/.go"
    set -q GOENV_GO_ROOT; and set root $GOENV_GO_ROOT
    set -l versions
    for dir in $root/*
        test -x "$dir/bin/go"; and set -a versions (string replace -r '.*/' '' -- $dir)
    end
    printf '%s\n' $versions | sort -V
    # Also offer the major.minor shorthands the wrapper resolves.
    printf '%s\n' $versions | string replace -rf '^([0-9]+\.[0-9]+)\.[0-9]+$' '$1' | sort -uV
end

# List remote versions eligible for installation.
function _bwgoenv_remote_versions
    command goenv --list-remote 2>/dev/null |
        string match -r '^[0-9]+\.[0-9]+(\.[0-9]+)?$' | sort -rV
end

# Match the selected subcommand, with or without leading dashes.
function _bwgoenv_using_cmd
    set -l tokens (commandline -opc)
    test (count $tokens) -eq 2; or return 1
    contains -- (string replace -r '^-+' '' -- $tokens[2]) $argv
end

# Complete subcommands until one has been selected.
complete -c goenv -n "not __fish_seen_subcommand_from $_bwgoenv_cmds" \
    -a "use\t'Use an installed version'
install\t'Install a version'
uninstall\t'Uninstall a version'
list\t'List installed versions'
list-remote\t'List remote versions'
help\t'Show help'"

# Complete installed versions for use and uninstall.
complete -c goenv -n '_bwgoenv_using_cmd use uninstall' -k \
    -a '(_bwgoenv_installed_versions)'
# Complete remote versions for install.
complete -c goenv -n '_bwgoenv_using_cmd install' -k -a '(_bwgoenv_remote_versions)'
