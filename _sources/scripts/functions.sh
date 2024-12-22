# read variables from LocalSettings.php
get_mediawiki_variable () {
    php /getMediawikiSettings.php --variable="$1" --format="${2:-string}"
}

isTrue() {
    case $1 in
        "True" | "TRUE" | "true" | 1)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

get_hostname_with_port () {
    local port
    port=$(echo "$1" | grep ":" | cut -d":" -f2)
    echo "$1:${port:-$2}"
}

make_dir_writable() {
    find "$@" '(' -type f -o -type d ')' \
       -not '(' '(' -user "$WWW_USER" -perm -u=w ')' -o \
           '(' -group "$WWW_GROUP" -perm -g=w ')' -o \
           '(' -perm -o=w ')' \
         ')' \
         -exec chgrp "$WWW_GROUP" {} \; -exec chmod g=rwX {} \;
}

export_vars_from_docker_secret_files() {
    [ -f /etc/environment_secrets ] && rm /etc/environment_secrets

    # Iterate over all environment variables ending with '_FILE'
    for env_var in $(compgen -v | grep '_FILE$'); do
        base_var="${env_var%_FILE}" # Get variable name without the "_FILE" suffix

        # Skip if the base variable is already defined
        if [[ -n "${!base_var}" ]]; then
            continue
        fi

        file_paths="${!env_var}" # Get paths to secret files

        # Process each file path and use the first valid one
        for file_path in $file_paths; do
            if [[ -f "$file_path" && -r "$file_path" ]]; then
                # Read file content
                content=$(<"$file_path")

                # Export the variable for the current session
                export "$base_var=$content"

                # Append the updated value to /etc/environment_secrets
                echo "$base_var=$content" >> /etc/environment_secrets

                echo "* Defined variable $base_var with value from $file_path"
                break # Stop after first valid file
            fi
        done
    done
}
