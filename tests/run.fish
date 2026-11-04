#!/usr/bin/env fish
# Each case runs in a throwaway HOME so universal variables never touch your real fish config.

set -g repo (realpath (status dirname)/..)
set -g failed 0

function check --argument-names name code
    set -l tmp (mktemp -d)
    mkdir -p $tmp/bin $tmp/config

    # Fake goenv: logs its arguments and serves a fixed remote release list.
    printf '%s\n' '#!/bin/sh' \
        'case "$1" in' \
        '    --list-remote) printf "%s\n" 1.23.0 1.24.1 1.24.2 1.24rc1 1.25rc1 ;;' \
        '    *) echo "$*" >>"$GOENV_TEST_LOG" ;;' \
        esac >$tmp/bin/goenv
    chmod +x $tmp/bin/goenv

    for ver in 1.23.0 1.24.1 1.24.3
        mkdir -p $tmp/go/$ver/bin
        printf '#!/bin/sh\n' >$tmp/go/$ver/bin/go
        chmod +x $tmp/go/$ver/bin/go
    end

    # --no-config is avoided because it keeps `set -e -U` from erasing universal variables.
    set -l output (env HOME=$tmp XDG_CONFIG_HOME=$tmp/config XDG_DATA_HOME=$tmp/data \
        PATH="$tmp/bin:$PATH" GOENV_GO_ROOT=$tmp/go GOENV_TEST_LOG=$tmp/log \
        fish -c "
            set -g plugin_dir $repo
            set -p fish_function_path $repo/functions
            source $repo/conf.d/bwgoenv.fish
            source $repo/completions/goenv.fish
            $code" 2>&1)
    set -l rc $status

    if test $rc -eq 0
        echo "ok - $name"
    else
        echo "not ok - $name"
        printf '    %s\n' $output
        set failed (math $failed + 1)
    end
    command rm -rf $tmp
end

check 'use expands major.minor to the newest installed patch' '
    goenv use 1.24
    and string match -q -- "--use 1.24.3" <$GOENV_TEST_LOG
    and contains -- $GOENV_GO_ROOT/1.24.3/bin $fish_user_paths
    and test "$_bwgoenv_managed_path" = $GOENV_GO_ROOT/1.24.3/bin'

check '--use=<major.minor> is expanded in place' '
    goenv --use=1.24
    and string match -q -- "--use=1.24.3" <$GOENV_TEST_LOG'

check 'switching versions replaces only the managed path' '
    set -U fish_user_paths /keep
    goenv use 1.23.0
    and goenv use 1.24.1
    and contains -- /keep $fish_user_paths
    and contains -- $GOENV_GO_ROOT/1.24.1/bin $fish_user_paths
    and not contains -- $GOENV_GO_ROOT/1.23.0/bin $fish_user_paths'

check 'missing version leaves PATH untouched' '
    set -U fish_user_paths /keep
    not goenv use 1.99.0
    and test "$fish_user_paths" = /keep
    and not set -q _bwgoenv_managed_path'

check 'install expands major.minor to the newest stable release' '
    goenv install 1.24
    and string match -q -- "--install 1.24.2" <$GOENV_TEST_LOG'

check 'bare subcommands are passed through as flags' '
    goenv list
    and string match -q -- --list <$GOENV_TEST_LOG'

check 'uninstall event removes only the managed path' '
    set -U fish_user_paths /keep
    goenv use 1.24.1
    and emit bwgoenv_uninstall
    and test "$fish_user_paths" = /keep
    and not set -q _bwgoenv_managed_path'

check '1.0.0 managed path variable is migrated' '
    set -U __fish_goenv_managed_path /old
    source $plugin_dir/conf.d/bwgoenv.fish
    test "$_bwgoenv_managed_path" = /old
    and not set -q __fish_goenv_managed_path'

check 'completions offer subcommands and versions' '
    complete -C "goenv " | string match -q "use*"
    and complete -C "goenv use " | string match -q 1.24.3
    and complete -C "goenv use " | string match -q 1.24
    and complete -C "goenv install " | string match -q 1.24.2
    and not complete -C "goenv install " | string match -q "*rc*"'

if test $failed -gt 0
    echo "$failed test(s) failed"
    exit 1
end
echo 'All tests passed.'
