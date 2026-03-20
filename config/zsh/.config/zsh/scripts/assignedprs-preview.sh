repo="$1"
number="$2"
author="$3"
title="$4"
updated="$5"
url="$6"
body_b64="$7"

if [[ -n "$body_b64" ]]; then
  body="$(printf '%s' "$body_b64" | base64 --decode 2>/dev/null)"
fi

wrap_width="${FZF_PREVIEW_COLUMNS:-80}"
if [[ "$wrap_width" -lt 20 ]]; then
  wrap_width=80
fi

printf '\033[1m%s\033[0m\n' "$title"
printf '\033[2m%s#%s\033[0m\n\n' "$repo" "$number"
printf 'author   %s\n' "$author"
printf 'updated  %s\n' "${updated/T/ }"
printf 'url      %s\n' "$url"
printf '\n\033[36mBody\033[0m\n'
if [[ -n "$body" ]]; then
  printf '%s\n' "$body" | fold -s -w "$wrap_width"
else
  printf '\033[2m(no body)\033[0m\n'
fi
