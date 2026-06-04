#!/usr/bin/env bash
set -euo pipefail
MD=$(ls *.md | grep -v README | head -1)
HTML="${MD%.md}.html"
CSS='body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;max-width:900px;margin:2rem auto;padding:0 1.5rem;color:#1a1a2e;line-height:1.65}h1{font-size:1.8rem;border-bottom:2px solid #005073;padding-bottom:.5rem}h2{font-size:1.3rem;margin-top:2rem;color:#005073}h3{font-size:1.1rem;color:#333}code{background:#f4f4f4;padding:.15em .4em;border-radius:3px;font-size:.9em}pre{background:#f4f4f4;padding:1rem;border-radius:4px;overflow-x:auto}table{border-collapse:collapse;width:100%;margin:1rem 0;font-size:.92em}th{background:#005073;color:#fff;padding:.5rem .75rem;text-align:left}td{padding:.45rem .75rem;border-bottom:1px solid #e2e2e2}tr:nth-child(even) td{background:#f9f9f9}blockquote{border-left:4px solid #005073;margin:0;padding:.5rem 1rem;background:#f0f7fb;color:#444}a{color:#0066cc}'
echo "$CSS" | pandoc "$MD" --standalone --embed-resources --metadata title="$(head -1 $MD | sed 's/^# //')" --css /dev/stdin -o "$HTML"
python3 strip_header.py "$HTML"
echo "Done: $HTML"
