# add all git sources of the repository to the local git config file

set -e

FILE=$(cat ./.git/config)
FILE=$(
    REMOTE=; url=; urls=;

    printf "%s" "$FILE" | { while IFS= read -r LINE || [ "$LINE" ]; do
        case "$LINE" in
            '[remote "origin"]')
                REMOTE="$REMOTE$LINE
"
                remote_flag=1
            ;;
            '['*)
                [ "$REMOTE" ] || { printf "%s\n" "$LINE"; continue; }

                REMOTE=$(printf "%s" "$REMOTE" | { while IFS= read -r _line; do
                    if [ ! "$url" ]; then
                        case "$_line" in
                            *'url = '*) url="$_line" ;;
                            *) printf "%s\n" "$_line" ;;
                        esac

                        continue
                    fi

                    case "$_line" in
                        *'url = '*)
                            urls="$urls${_line%.git}.git
"
                            continue
                        ;;
                    esac

                    printf "%s\n" "$url"

                    for _url in \
                    'https://github.com/mscalindt/scripts' \
                    'https://gitlab.com/mscalindt/scripts' \
                    'https://codeberg.org/mscalindt/scripts'; do
                        case "${url%.git}.git
$urls" in
                            *"url = ${_url%.git}.git
"*)
                            ;;
                            *)
                                urls="$urls	url = ${_url%.git}.git
"
                            ;;
                        esac
                    done

                    printf "%s" "$urls"
                    printf "%s\n" "$_line"
                    url=; urls=
                done; }; )

                printf "%s\n" "$REMOTE"
                printf "%s\n" "$LINE"
                REMOTE=
                remote_flag=
            ;;
            *)
                if [ "$remote_flag" ]; then
                    REMOTE="$REMOTE$LINE
"
                else
                    printf "%s\n" "$LINE"
                fi
            ;;
        esac
    done; }
)
printf "%s\n" "$FILE" > ./.git/config
