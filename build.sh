#!/bin/bash

set -e

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

iso_date="$(date +%Y.%m.)01"
iso_path="$(fetch_latest_iso "$iso_date")"

fetch_latest_iso_checksums
checksums="$(cat "${project_dir}/iso/md5sums.txt")"
md5="$(get_md5_checksum "$checksums")"
post_processors="$(add_relevant_post_processors $@)"

vm_name="packer-arch-linux-$(date +%Y%m%d%H%M%S)"

cd "$project_dir"
echo "$build_json" | jq ".\"post-processors\" = $post_processors" | \
  packer build \
    -var "iso_checksum=${md5}" \
    -var "local_iso_path=${iso_path}" \
    -var "vm_name=${vm_name}" \
    -force -
