#!/bin/bash

set -e

POST_PROCESSORS=

get_opts() {
  while getopts 'p:a' opt; do
    case "$opt" in
      a)
        read -s -p 'desired root password: ' DESIRED_ROOT_PASSWORD
        echo
        ;;
      p)
        POST_PROCESSORS="${POST_PROCESSORS}${OPTARG} "
        ;;
    esac
  done
}

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

add_relevant_post_processors() {
  post_processors_head="$1"
  shift
  post_processors_tail="$@"

  jq_select_string=".type == \"$post_processors_head\""

  for post_processor in $post_processors_tail; do
    jq_select_string="$jq_select_string or .type == \"$post_processor\""
  done

  echo "$build_json" | jq "[.\"post-processors\"[] | select($jq_select_string)]"
}

process_build_json() {
  local build_json="$1"
  local post_processors="$2"
  local variables="$3"

  # reset post-processors (for filtering), but merge variables
  build_json="$(echo "$build_json" | \
    jq ".\"post-processors\" = $post_processors")"
  build_json="$(echo "$build_json" | \
    jq ".variables = .variables * $variables")"
  echo "$build_json"
}

generate_additional_variables() {
  local vars_json='{}'
  if [ -n "$DESIRED_ROOT_PASSWORD" ]; then
    vars_json="$(echo "$vars_json" | \
      jq ".desired_root_password = \"$DESIRED_ROOT_PASSWORD\"")"
  fi
  echo "$vars_json"
}

fetch_latest_iso() {
  local date="$1"
  local iso_name="archlinux-${date}-x86_64.iso"
  if ! [ -f "${project_dir}/iso/$iso_name" ]; then
    find "${project_dir}/iso/"* -type f -exec rm -f {} \; > /dev/null
    curl -sL "http://mirror.bytemark.co.uk/archlinux/iso/latest/$iso_name" \
      -o "${project_dir}/iso/$iso_name"
  fi
  echo "${project_dir}/iso/$iso_name"
}

fetch_latest_iso_checksums() {
  curl -sL 'http://mirror.bytemark.co.uk/archlinux/iso/latest/md5sums.txt' \
    -o "${project_dir}/iso/md5sums.txt"
}

get_md5_checksum() {
  local checksums="$@"
  echo "$checksums" | grep '.iso' | awk '{print $1}'
}

print_info() {
  local comma_separated_post_processors="$( \
    echo "${POST_PROCESSORS}" | sed -e 's/ /, /g' -e 's/\(.*\),/\1./g')"
  echo "Using post-processors $comma_separated_post_processors"
}

get_opts "$@"

print_info

iso_date="$(date +%Y.%m.)01"
iso_path="$(fetch_latest_iso "$iso_date")"

fetch_latest_iso_checksums
checksums="$(cat "${project_dir}/iso/md5sums.txt")"
md5="$(get_md5_checksum "$checksums")"
post_processors="$(add_relevant_post_processors $POST_PROCESSORS)"
additional_variables="$(generate_additional_variables)"

vm_name="packer-arch-linux-$(date +%Y%m%d%H%M%S)"
build_json="$(process_build_json \
  "$(cat "${project_dir}/build.json")" \
  "${post_processors}" \
  "${additional_variables}"
)"

cd "$project_dir"
echo  "$build_json" | packer build \
  -var "iso_checksum=${md5}" \
  -var "local_iso_path=${iso_path}" \
  -var "vm_name=${vm_name}" \
  -force -
