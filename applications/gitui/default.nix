{ pkgs, ... }:
{
  programs = {
    gitui = {
      enable = true;
      keyConfig = ''
        (
            open_help: Some(( code: F(1), modifiers: ( bits: 0,),)),

            move_left: Some(( code: Char('h'), modifiers: ( bits: 0,),)),
            move_right: Some(( code: Char('l'), modifiers: ( bits: 0,),)),
            move_up: Some(( code: Char('k'), modifiers: ( bits: 0,),)),
            move_down: Some(( code: Char('j'), modifiers: ( bits: 0,),)),

            popup_up: Some(( code: Char('p'), modifiers: ( bits: 2,),)),
            popup_down: Some(( code: Char('n'), modifiers: ( bits: 2,),)),
            page_up: Some(( code: Char('b'), modifiers: ( bits: 2,),)),
            page_down: Some(( code: Char('f'), modifiers: ( bits: 2,),)),
            home: Some(( code: Char('g'), modifiers: ( bits: 0,),)),
            end: Some(( code: Char('G'), modifiers: ( bits: 1,),)),
            shift_up: Some(( code: Char('K'), modifiers: ( bits: 1,),)),
            shift_down: Some(( code: Char('J'), modifiers: ( bits: 1,),)),

            edit_file: Some(( code: Char('I'), modifiers: ( bits: 1,),)),

            status_reset_item: Some(( code: Char('U'), modifiers: ( bits: 1,),)),

            diff_reset_lines: Some(( code: Char('u'), modifiers: ( bits: 0,),)),
            diff_stage_lines: Some(( code: Char('s'), modifiers: ( bits: 0,),)),

            stashing_save: Some(( code: Char('w'), modifiers: ( bits: 0,),)),
            stashing_toggle_index: Some(( code: Char('m'), modifiers: ( bits: 0,),)),

            stash_open: Some(( code: Char('l'), modifiers: ( bits: 0,),)),

            abort_merge: Some(( code: Char('M'), modifiers: ( bits: 1,),)),
        )
      '';
      theme = ''
        (
            selected_tab: Reset,
            command_fg: Blue,
            selection_bg: DarkGray,
            selection_fg: White,
            cmdbar_bg: Black,
            cmdbar_extra_lines_bg: DarkGray,
            disabled_fg: DarkGray,
            diff_line_add: Green,
            diff_line_delete: Red,
            diff_file_added: LightGreen,
            diff_file_removed: LightRed,
            diff_file_moved: LightMagenta,
            diff_file_modified: Yellow,
            commit_hash: Magenta,
            commit_time: LightCyan,
            commit_author: Green,
            danger_fg: Red,
            push_gauge_bg: Blue,
            push_gauge_fg: Reset,
            tag_fg: LightMagenta,
            branch_fg: LightYellow,
        )
      '';
    };
  };
}
