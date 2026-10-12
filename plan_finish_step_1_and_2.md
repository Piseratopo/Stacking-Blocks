# Implementation Plan: Completing Step 1 & Step 2

This plan outlines the exact changes required to finalize **Step 1 (Board Refactoring)** and **Step 2 (Ownership & Garbage Engine)** from [multiplayer_implementation_plan.md](file:///d:/Projektoj/Stacking-Blocks/multiplayer_implementation_plan.md).

---

## Architecture Overview

```
                      +-----------------------------+
                      |       obj_controller        |
                      |   (Match / System Manager)  |
                      |  - Init global properties   |
                      |  - Spawns local board       |
                      |  - (Future: Network & Opp.) |
                      +--------------+--------------+
                                     |
                                     v
                      +-----------------------------+
                      |      obj_player_board       |
                      |   (Self-Contained Board)    |
                      |  - is_local / slot_index    |
                      |  - grid_start_x / bottom_y  |
                      |  - play_grid dynamic array  |
                      |  - Attacks, combos & b2b    |
                      |  - Garbage queue & cancel   |
                      |  - Next & Hold frame UI     |
                      |  - Spawns own borders       |
                      +--------------+--------------+
                                     |
                        spawns & manages (board_owner)
                                     |
                   +-----------------+-----------------+
                   |                                   |
                   v                                   v
          +-----------------+                 +-----------------+
          |    obj_shape    |                 |    obj_block    |
          |  Falling Piece  |                 |  Locked Blocks  |
          +-----------------+                 +-----------------+
```

---

## Phase 1: Completing Step 1 (Board Refactoring)

### 1.1 Activate `obj_player_board`
Currently, `obj_player_board` exists as an empty asset in the project without code. We will migrate board-specific mechanics from `obj_controller` into `obj_player_board`:

1. **`obj_player_board/Create_0.gml`**:
   - Board identity & position configuration:
     ```gml
     is_local = true;
     player_id = "";
     slot_index = 0;
     player_name = "Player 1";
     is_alive = true;

     // Board positioning
     grid_start_x = GRID_START_X;
     grid_bottom_y = GRID_BOTTOM_Y;
     grid_width = GRID_WIDTH;
     grid_height = GRID_HEIGHT;
     cell_size = CELL_SIZE;
     ```
   - Board state:
     ```gml
     current_shape = noone;
     next_shape_name = get_random_shape();
     hold_shape_name = "";
     can_hold = true;
     finished_locking_shape = false;
     total_lines_cleared = 0;
     combo_count = -1;
     b2b_active = false;
     incoming_garbage = 0;
     ```
   - Grid methods:
     - `grid_set(_col, _row, _shape_name)`
     - `grid_get(_col, _row)`
     - `is_row_full(_row)`
     - `spawn_shape(_shape_name)`
     - `get_spawn_y()`
   - Dynamic Border Generation:
     - Instead of relying on hardcoded `obj_border` instances in `rm_play`, `obj_player_board` spawns its own border walls and floor dynamically using `grid_start_x`, `grid_bottom_y`, `grid_width`, and `grid_height`. This allows boards to be positioned anywhere on screen (left, right, scaled) without needing room editor edits.

2. **`obj_player_board/Step_0.gml`**:
   - Local input handling (Hold action, Next shape queueing).
   - Post-lock shape trigger (`apply_garbage()`, lock sprite autotiling, clearing flags).

3. **`obj_player_board/Draw_0.gml`**:
   - Draw Next piece frame and Hold frame anchored to `grid_start_x` and `grid_bottom_y`.
   - Draw incoming garbage danger gauge.
   - If not alive, draw "K.O." overlay.

### 1.2 Refactor `obj_controller` to Orchestrator
- Retain global initialization: `randomise()`, `global.shape_properties`, `global.block_lock_sprite_map`, bag setup.
- In `rm_play`: Spawns the primary local board:
  ```gml
  local_board = instance_create_layer(0, 0, "Controllers", obj_player_board, {
      is_local: true,
      grid_start_x: GRID_START_X,
      grid_bottom_y: GRID_BOTTOM_Y,
      slot_index: 0
  });
  ```
- Strips single-board grid logic out of `obj_controller`.

---

## Phase 2: Completing Step 2 (Ownership, Versus Mechanics & Garbage Engine)

### 2.1 Complete Border Decoupling in `obj_block` & `obj_shape`
Currently, `obj_block/Step_0.gml` and `obj_shape/Create_0.gml` use `place_meeting(..., obj_border)`.
- Because `obj_player_board` spawns tagged borders (or because board bounds are strictly checked via `grid_start_x` and `grid_bottom_y`), pieces will only interact with:
  1. Borders spawned by their own `board_owner`.
  2. Locked blocks that belong to their own `board_owner` (`_inst.board_owner == board_owner`).
- Update `hard_drop`, `is_touching_left`, `is_touching_right`, and vertical drop checks to verify board ownership so opponent blocks and opponent borders never cause false collisions.

### 2.2 Line Clear Attack Table & Multipliers
Update `clear_lines()` in `obj_player_board`:
```gml
clear_lines = function() {
    var _lines_cleared = 0;
    var _r = 0;
    var _owner = id;

    while (_r < array_length(play_grid)) {
        if (is_row_full(_r)) {
            var _row_y = grid_row_to_y(_r, grid_bottom_y);
            with (obj_block) {
                if (board_owner == _owner && is_locked && y == _row_y) instance_destroy();
            }
            with (obj_block) {
                if (board_owner == _owner && is_locked && y < _row_y) y += CELL_SIZE;
            }
            array_delete(play_grid, _r, 1);
            _lines_cleared++;
        } else {
            _r++;
        }
    }

    if (_lines_cleared > 0) {
        total_lines_cleared += _lines_cleared;
        combo_count++;

        // Base attack
        var _attack = 0;
        var _is_difficult = (_lines_cleared == 4);

        switch (_lines_cleared) {
            case 1: _attack = 0; break;
            case 2: _attack = 1; break;
            case 3: _attack = 2; break;
            case 4: _attack = 4; break;
        }

        // Back-to-Back (B2B) bonus
        if (_is_difficult) {
            if (b2b_active) _attack += 1;
            b2b_active = true;
        } else {
            b2b_active = false;
        }

        // Combo bonus
        if (combo_count > 0) {
            _attack += min(combo_count, 5); // Capped combo scaling
        }

        // Perfect Clear (All Clear) bonus
        if (array_length(play_grid) == 0) {
            _attack += 10;
        }

        // Garbage Countering / Cancellation
        if (incoming_garbage > 0) {
            var _canceled = min(incoming_garbage, _attack);
            incoming_garbage -= _canceled;
            _attack -= _canceled;
        }

        // Dispatch outgoing attack if lines remain
        if (_attack > 0) {
            send_attack(_attack);
        }
    } else {
        combo_count = -1; // Reset combo if piece locked without clearing lines
    }

    return _lines_cleared;
};
```

### 2.3 Refined Garbage Engine
1. **Attack Dispatch Stub (`send_attack`)**:
   - For Step 2 local testing: can either log or loop back to opponent.
   - Sets up clean hooks for Step 4's `network_send({"attack_send": ...})`.
2. **Rising Garbage Conditions**:
   - In `Step_0.gml`: only trigger `apply_garbage()` if `_lines_cleared == 0` (players have an opportunity to counter before garbage rises).
   - In `apply_garbage()`: support random hole positioning or synchronized hole positioning (`_hole_col`).

### 2.4 Knockout / Top-Out Detection (`on_player_ko`)
Implement KO detection in `obj_player_board`:
- **Conditions**:
  1. A block locks with `y < grid_bottom_y - grid_height * CELL_SIZE`.
  2. A new piece spawns in `spawn_shape()` and immediately collides with existing locked blocks.
- **Handling**:
  ```gml
  on_player_ko = function() {
      if (!is_alive) exit;
      is_alive = false;
      if (instance_exists(current_shape)) {
          instance_destroy(current_shape);
          current_shape = noone;
      }
      show_debug_message("PLAYER K.O.: " + string(player_id));
      // Ready for network broadcast in Step 4
  };
  ```

---

## File Modification Plan

| File | Action | Description |
|---|---|---|
| `Stacking Blocks/objects/obj_player_board/Create_0.gml` | Create | Full board state, methods, coordinate conversions, and border spawner |
| `Stacking Blocks/objects/obj_player_board/Step_0.gml` | Create | Input handling, piece queueing, garbage activation, top-out check |
| `Stacking Blocks/objects/obj_player_board/Draw_0.gml` | Create | Next/Hold piece frame UI and garbage gauge relative to board position |
| `Stacking Blocks/objects/obj_controller/Create_0.gml` | Modify | Remove board-specific logic; spawn and manage `obj_player_board` instance(s) |
| `Stacking Blocks/objects/obj_controller/Step_0.gml` | Modify | Simplify to match/game orchestrator |
| `Stacking Blocks/objects/obj_controller/Draw_0.gml` | Modify | Delegate board rendering to `obj_player_board` |
| `Stacking Blocks/objects/obj_block/Step_0.gml` | Modify | Ensure collision strictly respects `board_owner` |
| `Stacking Blocks/objects/obj_shape/Create_0.gml` | Modify | Top-out detection on lock & board boundary checks in `hard_drop` |
| `multiplayer_implementation_plan.md` | Update | Mark Step 1 and Step 2 as completed once tested |

---

## Verification & Testing Steps

1. **Single Board Regression**: Run the game and verify single-player play (movement, rotation, SRS kicks, hard drop, soft drop, hold piece) functions identically.
2. **Dynamic Positioning**: Change `grid_start_x` to another position (e.g. `280` or `920`) and confirm that the entire board, borders, falling pieces, and Next/Hold UI shift cleanly.
3. **Versus Mechanics Testing**:
   - Clear lines (Single, Double, Triple, Tetris) and verify combo and B2B bonuses calculate properly via debug logs.
   - Inject test garbage via `receive_garbage(4)`: verify the danger meter rises.
   - Clear 2 lines: verify danger meter reduces to 2 (countering/cancellation).
   - Lock a piece without clearing lines: verify 2 garbage rows push upward with holes.
4. **Top-Out Check**: Stack blocks to the ceiling; verify `on_player_ko()` triggers smoothly without crashing.
