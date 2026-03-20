pr_b64="$1"

if [[ -z "$pr_b64" ]]; then
  echo "Missing PR payload"
  exit 1
fi

printf '%s' "$pr_b64" | base64 --decode | jq -r '
  def c(code; s): "\u001b[" + code + "m" + s + "\u001b[0m";
  def bold(s): c("1"; s);
  def dim(s): c("2"; s);
  def cyan(s): c("36"; s);
  def yellow(s): c("33"; s);
  def green(s): c("32"; s);
  def section(s): "\n" + cyan(s);
  def fmt_date:
    if . == null then "-"
    else sub("T"; " ") | sub("Z$"; "")
    end;
  def fmt_state:
    if .isDraft then yellow("DRAFT")
    elif (.state | ascii_upcase) == "OPEN" then green("OPEN")
    else (.state | ascii_upcase)
    end;
  def fmt_labels:
    if (.labels | length) > 0 then
      (.labels | map(.name) | join(", "))
    else
      dim("none")
    end;
  def fmt_body:
    (.body // "")
    | gsub("\r\n"; "\n")
    | if length > 0 then . else dim("(no body)") end;

  . as $p |
  [
    bold($p.title),
    dim($p.repository.nameWithOwner + "#" + ($p.number | tostring)),
    "",
    "state    " + fmt_state,
    "author   " + ($p.author.name // $p.author.login) + " (" + $p.author.login + ")",
    "updated  " + ($p.updatedAt | fmt_date),
    "created  " + ($p.createdAt | fmt_date),
    "comments " + ($p.commentsCount | tostring),
    "locked   " + (if $p.isLocked then "yes" else "no" end),
    "labels   " + fmt_labels,
    "url      " + $p.url,
    section("Body"),
    ($p | fmt_body)
  ]
  | .[]
  '
