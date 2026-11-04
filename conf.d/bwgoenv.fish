# 1.0.0 stored the managed SDK path under this older name.
if set -q __fish_goenv_managed_path
    set -U _bwgoenv_managed_path $__fish_goenv_managed_path
    set -e -U __fish_goenv_managed_path
end

# Fisher emits this before deleting the plugin's files.
function _bwgoenv_uninstall --on-event bwgoenv_uninstall
    if set -q _bwgoenv_managed_path
        set -l kept
        for p in $fish_user_paths
            test "$p" = "$_bwgoenv_managed_path"; or set -a kept $p
        end
        set -U fish_user_paths $kept
        set -e -U _bwgoenv_managed_path
    end
    functions -e _bwgoenv_uninstall
end
