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

    # nvm-style subcommands: `goenv use 1.24` -> `goenv --use 1.24`.
    if test (count $argv) -gt 0
        switch $argv[1]
            case use install uninstall list list-remote help
                set argv[1] "--$argv[1]"
        end
    end

    # Detect a `--use <ver>` / `-use <ver>` (or `--use=<ver>`) invocation, and
    # remember where the version token sits in argv so we can rewrite it.
    set -l gover ""
    set -l gover_idx 0 # argv index holding the version token
    set -l gover_eq 0 # 1 when the `-use=<ver>` form was used
    set -l n (count $argv)
    for i in (seq $n)
        switch $argv[$i]
            case -use --use
                if test (math $i + 1) -le $n
                    set gover $argv[(math $i + 1)]
                    set gover_idx (math $i + 1)
                end
            case '-use=*' '--use=*'
                set gover (string replace -r '^-+use=' '' -- $argv[$i])
                set gover_idx $i
                set gover_eq 1
        end
    end

    # Expand a `major.minor` shorthand (e.g. 1.24) to the newest installed
    # `major.minor.patch` before the real binary sees it.
    if test -n "$gover"; and string match -qr '^[0-9]+\.[0-9]+$' -- $gover
        set -l resolved (_bwgoenv_latest_patch "$GOENV_GO_ROOT" $gover)
        if test -n "$resolved"
            set gover $resolved
            if test $gover_eq -eq 1
                set argv[$gover_idx] (string replace -r '=.*' "=$gover" -- $argv[$gover_idx])
            else
                set argv[$gover_idx] $gover
            end
        end
    end

    # Real goenv would download a nonexistent go1.24.tar.gz; resolve shorthand to newest release.
    set -l iidx 0
    set -l ieq 0
    for i in (seq $n)
        switch $argv[$i]
            case -install --install
                if test (math $i + 1) -le $n
                    set iidx (math $i + 1)
                end
            case '-install=*' '--install=*'
                set iidx $i
                set ieq 1
        end
    end
    if test $iidx -gt 0
        set -l iver (string replace -r '^-+install=' '' -- $argv[$iidx])
        if string match -qr '^[0-9]+\.[0-9]+$' -- $iver
            set -l resolved (_bwgoenv_latest_remote $iver)
            if test -n "$resolved"
                echo "goenv: resolving $iver -> $resolved (newest release)" >&2
                if test $ieq -eq 1
                    set argv[$iidx] (string replace -r '=.*' "=$resolved" -- $argv[$iidx])
                else
                    set argv[$iidx] $resolved
                end
            end
        end
    end

    # Run the real goenv binary (`command` bypasses this function to avoid recursion).
    command goenv $argv
    set -l rc $status

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
    set -l previous_bin "$_bwgoenv_managed_path"
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
    set -U _bwgoenv_managed_path $gobin

    echo "goenv: fish now using go $gover ($gobin)"
    return $rc
end

# Newest installed <major.minor>.<patch> under root; prints nothing if none.
function _bwgoenv_latest_patch --description 'Newest installed <root>/<major.minor>.<patch>'
    set -l root $argv[1]
    set -l series $argv[2]
    set -l candidates
    for dir in $root/$series.*
        test -x "$dir/bin/go"; and set -a candidates (string replace -r '.*/' '' -- $dir)
    end
    test (count $candidates) -eq 0; and return 1
    printf '%s\n' $candidates | sort -V | tail -n1
end

# Newest remote <major.minor>.<patch> release; skips rc/beta.
function _bwgoenv_latest_remote --description 'Newest remote <major.minor>.<patch> release'
    set -l series $argv[1]
    set -l escaped (string escape --style=regex -- $series)
    set -l matches (command goenv --list-remote 2>/dev/null |
        string match -r -- "^$escaped\.[0-9]+\$")
    test (count $matches) -eq 0; and return 1
    printf '%s\n' $matches | sort -V | tail -n1
end
