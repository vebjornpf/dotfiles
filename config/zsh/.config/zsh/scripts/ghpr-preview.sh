b64="$1"
echo "$b64" | base64 --decode | jq -C | less -R

