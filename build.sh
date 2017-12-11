#!/bin/bash

get_project_dir() {
  local project_path
  project_path="${BASH_SOURCE[0]%*/*}"
  if ! [[ "$project_path" == "${BASH_SOURCE[0]}" ]]; then
    cd "$project_path"
  fi
  pwd
}

project_dir="$(get_project_dir)"
build_json="$(cat "${project_dir}/build.json")"

post_processors_head="$1"
shift
post_processors_tail="$@"

jq_select_string=".type == \"$post_processors_head\""

for post_processor in $post_processors_tail; do
  jq_select_string="$jq_select_string or .type == \"$post_processor\""
done

cd "$project_dir"
post_processors="$(echo "$build_json" | jq "[.\"post-processors\"[] | select($jq_select_string)]")"
echo "$build_json" | jq ".\"post-processors\" = $post_processors" | packer build -force -
