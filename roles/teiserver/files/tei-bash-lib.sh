# A library of common shared functions for tei-* server scripts

export _TEI_INSTALL_DIR="/opt/teiserver"
export _TEI_DEPLOY_LOCK="/run/lock/teiserver-deploy.lock"

function _tei_list_tags {
    while read -r tag; do
        local target
        if target=$(readlink -e "$tag"); then
            printf "%s\t%s\n" $(basename "$tag") $(basename "$target")
        fi
    done < <(find $_TEI_INSTALL_DIR -maxdepth 1 -type l)
}

function _tei_list_versions {
    # Build a map from build versions to tags (filesystem links)
    declare -A tags
    while read -r tag version; do
        tags["$version"]="$tag ${tags["$version"]-}"
    done < <(_tei_list_tags)

    # Create an interactive table with list of versions
    while read -r build_info; do
        local version=$(dirname "$build_info")
        cat "$_TEI_INSTALL_DIR/$build_info" | jq \
            --arg tags "${tags["$version"]-}" \
            '. + {tags: $tags | rtrimstr(" ") }'
    done \
        < <(find $_TEI_INSTALL_DIR -maxdepth 2 -regextype posix-extended -regex "$_TEI_INSTALL_DIR/ver-[a-f0-9]{10}/build-info.json" -printf "%P\n") \
        | jq -s -r '.
            | sort_by(.time) | reverse | .[]
            | [
                .image[0:10],
                .time,
                .actor,
                .commit[0:7] + (if .dirty == "true" then "*" else "" end),
                .repo,
                .tags
              ]
            | @csv'
}

function _tei_select_version {
    _tei_list_versions \
        | gum table -c version,time,actor,commit,repo,tags -w11,20,10,8,30,500 --height=12 \
        | cut -d, -f1
}

function _tei_resolve_version {
    local ver="$1"
    if [[ -z "$ver" ]]; then
        gum style --bold "No version selected" >&2
        return 1
    elif [[ -d "$_TEI_INSTALL_DIR/ver-$ver" ]]; then
        echo "$ver"
    elif [[ -L "$_TEI_INSTALL_DIR/$ver" ]]; then
        echo $(readlink "$_TEI_INSTALL_DIR/$ver" | cut -d- -f2)
    else
        gum style --bold "Version $ver not found" >&2
        return 1
    fi
}

function _tei_lock_deploy {
    exec 200>>$_TEI_DEPLOY_LOCK

    local msg="Waiting for deploy lock held by $(cat $_TEI_DEPLOY_LOCK)..."
    if [ -t 0 ]; then
        gum spin --title "$msg" -- flock 200
    else
        if ! flock -n 200; then
            echo "$msg"
            flock 200
        fi
    fi
    echo "$(logname):$$" > $_TEI_DEPLOY_LOCK
}
