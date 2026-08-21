# fish-goenv: wraps the `goenv` Golang version manager so fish follows its
# active version. `goenv --use` only edits ~/.bashrc (which fish ignores), so
# here we run the real binary and, on `--use`, repoint fish's PATH ourselves.
function goenv --description 'goenv wrapper: keeps fish PATH in sync with `goenv --use`'
    # Root where the ankitcharolia/goenv tool installs versions (~/.go/<ver>/bin).
    # Override by setting `set -Ux GOENV_GO_ROOT /custom/path`.
    set -q GOENV_GO_ROOT; or set -l GOENV_GO_ROOT "$HOME/.go"

    # Nothing to wrap if the real binary isn't installed.
    if not command -q goenv
        echo "goenv: real `goenv` binary not found on PATH" >&2
        return 127
    end

    # Run the real goenv binary (`command` bypasses this function to avoid recursion).
    command goenv $argv
    set -l rc $status

    # Detect a `--use <ver>` / `-use <ver>` (or `--use=<ver>`) invocation.
    set -l gover ""
    set -l n (count $argv)
    for i in (seq $n)
        switch $argv[$i]
            case -use --use
                if test (math $i + 1) -le $n
                    set gover $argv[(math $i + 1)]
                end
            case '-use=*' '--use=*'
                set gover (string replace -r '^-+use=' '' -- $argv[$i])
        end
    end

    # Only PATH changes need our help; for every other command just pass through.
    test -z "$gover"; and return $rc

    # Keep the current SDK when goenv rejects the requested version.
    test $rc -ne 0; and return $rc

    # The version's go binary must actually exist before we switch to it.
    set -l gobin "$GOENV_GO_ROOT/$gover/bin"
    if not test -x "$gobin/go"
        echo "goenv: go binary not found at $gobin" >&2
        return 1
    end

    # Track the exact SDK path added by this plugin.
    set -l previous_bin "$__fish_goenv_managed_path"
    if test -n "$previous_bin"
        # Preserve every user-managed path while removing the old SDK path.
        set -l cleaned
        for p in $fish_user_paths
            test "$p" = "$previous_bin"; or set -a cleaned $p
        end
        set -U fish_user_paths $cleaned
    end

    # Make the new SDK available in every Fish session.
    fish_add_path -U $gobin
    set -U __fish_goenv_managed_path $gobin

    echo "goenv: fish now using go $gover ($gobin)"
    return $rc
end
