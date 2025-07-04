# shellcheck disable=SC2148
kitty @ launch --type=overlay --allow_remote_control sh -c "
  temp_dir=$(mktemp -d)

  get_all_tab() {
    kitty @ ls | jq -r '
      .[]
      | select(.is_active)
      | .tabs[]
      | .windows[]
      | [.title, .id]
      | @tsv
    ' > \$temp_dir/candidates
  }

  get_tab_preview() {
    cat \$temp_dir/candidates | awk '{ print \$NF }' | xargs -L1 -I{} sh -c \"kitty @ get-text --match id:{} > \$temp_dir/{}\"
  }

  get_tab_id() {
    cat \$temp_dir/candidates | fzf --reverse --preview \"cat \\\"\${temp_dir}\\\"/{-1}\" | awk '{ print \$NF }'
  }

  get_all_tab
  get_tab_preview
  kitty @ focus-tab --match id:\$(get_tab_id)

  rm -rf \$temp_dir
"
