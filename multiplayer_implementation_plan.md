# Multiplayer Implementation Plan: Stacking Blocks

This document details the complete technical roadmap for implementing online multiplayer for **Stacking Blocks**, starting with **Online 1v1 Versus** and architected from the ground up to seamlessly scale to **1 vs Many (Free-For-All / Battle Royale / Multi-Board)** in the future.

---

## 1. Architectural Vision: 1v1 Now, 1 vs Many Ready

```
                      +---------------------------------------+
                      |         Python Backend Server         |
                      |           (Backend/main.py)           |
                      |  - Room Code Generator (4 letters)    |
                      |  - Dynamic Room Slots (2 to N players)|
                      |  - Synchronized Match RNG Seed        |
                      |  - Garbage Routing & Targeting Engine |
                      +-------------------+-------------------+
                                          |
                        TCP Raw JSON Streams (Port 5001)
                        Framing: [{//V//}] Delimiter
                                          |
                +-------------------------+-------------------------+
                |                                                   |
                v                                                   v
+-------------------------------+                   +-------------------------------+
|     Player 1 Client (GM)      |                   |     Player 2 Client (GM)      |
|                               |                   |                               |
| [obj_network_manager]         |                   | [obj_network_manager]         |
|                               |                   |                               |
| [obj_controller (Match Mgr)]  |                   | [obj_controller (Match Mgr)]  |
|   - Spawns local & remotes    |                   |   - Spawns local & remotes    |
|                               |                   |                               |
| [obj_player_board (Local)]    |                   | [obj_player_board (Local)]    |
|   - Zero latency local input  |                   |   - Zero latency local input  |
|                               |                   |                               |
| Array: remote_boards[0..N-1]  |                   | Array: remote_boards[0..N-1]  |
|   - remote_boards[0] (P2)     |                   |   - remote_boards[0] (P1)     |
|   - (Room for P3..PN future)  |                   |   - (Room for P3..PN future)  |
+-------------------------------+                   +-------------------------------+
```

### Core Architecture Highlights
1. **Extensible Board System**:
   - The client [`obj_controller`](file:///home/piseratopo/Desktop/Projektoj/Stacking-Blocks/Stacking%20Blocks/objects/obj_controller/Create_0.gml) orchestrates a single **Local Board** ([`obj_player_board`](file:///home/piseratopo/Desktop/Projektoj/Stacking-Blocks/Stacking%20Blocks/objects/obj_player_board/Create_0.gml) with `is_local = true`) and a dynamic array of **Remote Boards** (`remote_boards = []`).
   - In 1v1 mode, `remote_boards` contains 1 full-sized opponent board.
   - In 1 vs Many mode, `remote_boards` can hold up to $N$ scaled/miniaturized boards arranged in a grid or along the periphery, requiring zero changes to the underlying simulation logic.
2. **Room Code System**:
   - Host clicks **Create Room** -> Server returns a unique 4-letter alphanumeric code (e.g., `WXYZ`).
   - Opponents click **Join Room** -> Enter code -> Handshake verifies availability.
   - Rooms support configurable capacities (`max_players = 2` for 1v1, configurable up to 4, 8, or more later).
3. **Garbage Routing & Targeting Abstraction**:
   - In 1v1: Garbage attacks are sent directly to the only opponent.
   - Extensible for 1 vs Many: Attack events include a `target_mode` (e.g., `Random`, `Attacker`, `Highest Stack`, or `Badges/KO`), resolved by the server without altering the core block-stacking engine.

---

## 2. Phase 1: Decoupling GameMaker Logic (Single-Board -> Multi-Board) - [COMPLETED]

Previously, `obj_controller` and macros hardcoded single-board coordinates and global references. The architecture has now been cleanly refactored:

### 2.1 Parameterized Board Component (`obj_player_board`)
All board-specific logic lives in [`obj_player_board`](file:///home/piseratopo/Desktop/Projektoj/Stacking-Blocks/Stacking%20Blocks/objects/obj_player_board/Create_0.gml):
- **Board Coordinates & Identity**:
  ```gml
  is_local      = true;
  slot_index    = 0;
  player_id     = "local";
  player_name   = "Player 1";
  is_alive      = true;

  grid_start_x  = GRID_START_X;
  grid_bottom_y = GRID_BOTTOM_Y;
  grid_width    = GRID_WIDTH;
  grid_height   = GRID_HEIGHT;
  cell_size     = CELL_SIZE;
  ```
- **Self-Contained Methods**: `grid_set`, `grid_get`, `is_row_full`, `clear_lines`, `spawn_shape`, and `get_spawn_y` bound directly to the board instance.
- **Dynamic Border Spawner**: `spawn_borders()` automatically builds walls and floor relative to `grid_start_x` and `grid_bottom_y` (or tags room-placed borders), tagged with `board_owner = id`.

### 2.2 Board Ownership for Shapes and Blocks
- When spawning a piece in `spawn_shape()`, assign `board_owner = id`:
  ```gml
  var _inst = instance_create_layer(_spawn_x, _spawn_y, "Blocks", obj_shape, {
      board_owner:  id,
      shape_name:   _shape_name,
      shape_data:   _shape_props[$ _shape_name],
      sprite_index: _shape_props[$ _shape_name].display_spr,
      lock_spr:     _shape_props[$ _shape_name].lock_spr,
      orientation:  0
  });
  ```
- In [`obj_shape`](file:///home/piseratopo/Desktop/Projektoj/Stacking-Blocks/Stacking%20Blocks/objects/obj_shape/Create_0.gml) and [`obj_block`](file:///home/piseratopo/Desktop/Projektoj/Stacking-Blocks/Stacking%20Blocks/objects/obj_block/Create_0.gml):
  - Uses `board_owner.grid_set()`, `board_owner.clear_lines()`, and `board_owner.calculate_and_send_attack()`.
  - Boundary and collision checks use `board_owner.grid_start_x`, `board_owner.grid_width`, and `board_owner.is_local`.
  - Directional collision methods: `is_touching_left()`, `is_touching_right()`, and `is_touching_up()`.

### 2.3 Refactored Match Orchestrator (`obj_controller`)
- [`obj_controller`](file:///home/piseratopo/Desktop/Projektoj/Stacking-Blocks/Stacking%20Blocks/objects/obj_controller/Create_0.gml) serves purely as Match / System Orchestrator.
- Spawns the local board:
  ```gml
  local_board = instance_create_layer(0, 0, "Controllers", obj_player_board, {
      is_local:      true,
      slot_index:    0,
      grid_start_x:  GRID_START_X,
      grid_bottom_y: GRID_BOTTOM_Y
  });
  ```
- Maintains `remote_boards = []` and `spawn_remote_board()` helper to dynamically instantiate opponent boards in Step 4+.

---

## 3. Phase 2: Versus Mechanics & Garbage System - [COMPLETED]

### 3.1 Sixth-Counter Attack System & Spin Bonus
Implemented in [`obj_player_board/Create_0.gml`](file:///home/piseratopo/Desktop/Projektoj/Stacking-Blocks/Stacking%20Blocks/objects/obj_player_board/Create_0.gml) via `calculate_and_send_attack(_lines_cleared, _is_spin)`:
- **Sixth-Counters**: Attacks are tracked in 1/6th line units so fractional bonuses accumulate across locks:
  - **Simultaneous Line Clear (Slc)**: $Slc = 2 \times N \times (N - 1)$ sixth-counters ($N =$ lines cleared; yields 0, 0, 4, 12, 24 sixths for 0, 1, 2, 3, 4 lines).
  - **Combo (Cb)**: $Cb = \max(0, \text{combo\_count})$ sixth-counters. Combo starts at 0 on first clear and increments per consecutive clear; resets to -1 on 0-line lock.
  - **Spin Bonus (Sp)**: $Sp = 6 \times N$ sixth-counters if the clear is a spin.
- **Immobile Spin Check**:
  - A spin is recognized when a tetromino locks in a position where it cannot move left, right, or up:
    ```gml
    var _is_spin = (!is_touching_left() && !is_touching_right() && !is_touching_up());
    ```
  - Evaluated in `obj_shape.lock_shape()` before creating locked blocks to avoid colliding with self. All pieces can spin.
- **Back-to-Back (B2B-burst)**:
  - **Difficult clear** ($N \ge 4$ or any spin): increments `b2b_count` chain by 1; no burst sent this turn.
  - **Normal clear** ($1 \le N \le 3$, no spin): breaks chain, sets `b2b_count = 0`, and fires a burst of $B = 6 \times \text{b2b\_count}$ sixth-counters.
  - **Zero-line lock**: preserves `b2b_count` chain.
- **Total & Remainder Carry**:
  $$\text{Tot} = (\text{Slc} + \text{Cb} + \text{Sp} + B + \text{Special} + \text{Past}) \times \text{Multiplier}$$
  $$\text{Lines Sent} = \lfloor \text{Tot} / 6 \rfloor, \quad \text{past\_sixths} = \text{Tot} \pmod 6$$

### 3.2 Incoming Garbage Meter, Cancellation & Rising Rows
1. **Garbage Queueing (`receive_garbage(_lines, _hole_col)`)**: Incoming attacks queue into `pending_garbage`, storing the server-provided `_last_garbage_hole`.
2. **Garbage Countering / Cancellation**: Outgoing `_lines_sent` cancel `pending_garbage` before sending remainder to network.
3. **Rising from the Bottom (`apply_garbage()`)**: In `Step_0.gml` after piece lock, remaining `pending_garbage` rows push existing locked blocks upward. New gray garbage rows insert at bottom of `play_grid`, using the server-supplied hole column for the first row and random holes for subsequent rows.
4. **Knockout / Top-Out Detection**: During `apply_garbage()`, if any locked block exceeds the ceiling (`y < grid_bottom_y - grid_height * CELL_SIZE`), sets `is_alive = false` and triggers `obj_network_manager.send_ko()`.

---

## 4. Phase 3: Python Backend Architecture (`Backend/`) - [COMPLETED]

### 4.1 Server Hardening ([`Backend/suspengine.py`](file:///home/piseratopo/Desktop/Projektoj/Stacking-Blocks/Backend/suspengine.py))
- **Thread Safety**: Added `threading.Lock()` guarding `clientlist`, `userdata`, and room mappings.
- **Packet Delimiter Splitting**: Buffer parsing in `handleclient` splits on `[{//V//}]` to prevent fragmented JSON issues.
- **Clean Disconnects**: Emits room teardown/opponent notification if a socket disconnects abruptly.

### 4.2 Room System & State Machine ([`Backend/main.py`](file:///home/piseratopo/Desktop/Projektoj/Stacking-Blocks/Backend/main.py))
Implemented scalable room management architecture:

```python
class Room:
    def __init__(self, code, max_players=2):
        self.code = code
        self.max_players = max_players
        self.players = {}         # client_socket -> {"ready": bool, "alive": bool, "name": str}
        self.state = "LOBBY"      # "LOBBY", "COUNTDOWN", "IN_GAME", "GAME_OVER"
        self.match_seed = 0
```

- **Room Code Generator**: Random 4 uppercase characters (`random.choices(string.ascii_uppercase, k=4)`), ensuring uniqueness.
- **Match Lifecycle**:
  - `room_create`: Host creates room, receives 4-letter code.
  - `room_join`: Second player (and future players) enter code.
  - `room_ready`: When all players toggle ready, triggers 3-second countdown.
  - `match_start`: Distributes synchronized `match_seed` so all clients generate the exact same piece sequence.
  - `garbage_relay`: Receives attack from player, routes to opponent (or target in 1 vs many).
  - `player_topout`: Tracks surviving players until 1 remains; announces winner.

---

## 5. Phase 4: Network Protocol Specification

Packets conform to the existing `ext_suspendee` structure:
`{"<event>": <payload_data>, "identify": "<event>"}[{//V//}]`

| Event | Direction | Payload | Description |
|---|---|---|---|
| `room_create` | Client -> Server | `{"max_players": 2}` | Host requests new room creation. |
| `room_created` | Server -> Client | `{"code": "WXYZ", "slot": 0}` | Confirms room code for sharing. |
| `room_join` | Client -> Server | `{"code": "WXYZ"}` | Join room with code. |
| `room_joined` | Server -> Client | `{"success": true, "code": "WXYZ", "slot": 1}` | Confirms join or returns error. |
| `room_update` | Server -> All | `{"players": [{"slot": 0, "ready": true}, ...]}` | Broadcasts lobby state. |
| `player_ready` | Client -> Server | `{"ready": true}` | Toggles player readiness. |
| `match_start` | Server -> All | `{"seed": 738291, "countdown": 3}` | Synchronizes piece RNG and starts game. |
| `piece_sync` | Client -> Server -> Opponents | `{"slot": 0, "x": 512, "y": 1400, "shape": "T", "rot": 0}` | Ghost piece sync for smooth opponent rendering. |
| `piece_locked` | Client -> Server -> Opponents | `{"slot": 0, "lines_cleared": 2, "blocks": [...]}` | Board state update on block placement. |
| `attack_send` | Client -> Server | `{"from_slot": 0, "lines": 2, "hole_col": 3}` | Sends garbage attack to be routed by server. |
| `attack_receive`| Server -> Client | `{"lines": 2, "hole_col": 3}` | Applies incoming garbage lines to target board. |
| `player_ko` | Client -> Server | `{"slot": 0}` | Signals player elimination. |
| `match_over` | Server -> All | `{"winner_slot": 1}` | Declares winner and returns to lobby. |

---

## 6. Phase 5: Client-Side Implementation in GameMaker (Upcoming)

### 6.1 `obj_network_manager`
- Persistent object initialized in the title room.
- Manages socket connection to `127.0.0.1:5001` (or remote IP).
- Binds event callbacks via `network_listen()`.
- Dispatches state updates to local and remote board objects.

### 6.2 Remote Board Representation (`obj_player_board` with `is_local = false`)
- Spawned dynamically via `obj_controller.spawn_remote_board(...)` at `x = 920` (or grid layout for 1 vs many).
- Holds an independent `play_grid` and renders locked blocks with autotiled sprites.
- Listens to `piece_sync` to render the opponent's active falling piece with smooth interpolation.
- Extensible: multiple remote boards can be instantiated and arranged dynamically for 1 vs many.

### 6.3 Lobby UI & Room Code Screens
1. **Multiplayer Menu**:
   - `[Create Room]` button -> creates room and transitions to Lobby.
   - `[Join Room]` button -> opens 4-character text input box.
2. **Lobby Room**:
   - Displays prominent room code (e.g. `ROOM: WXYZ`).
   - Shows connected player list and "Ready" indicators.
   - 3-2-1 countdown overlay upon all players ready.

---

## 7. Step-by-Step Implementation Checklist

- [x] **Step 1: Board Refactoring**: Decouple `obj_controller` into Match Orchestrator and `obj_player_board` self-contained board instances with parameterized coordinates.
- [x] **Step 2: Ownership & Garbage Engine**: Link `obj_shape` and `obj_block` to `board_owner`; sixth-counter attack system, immobile spin check, garbage cancellation queue, and line push mechanism.
- [x] **Step 3: Backend Room System**: Harden [`Backend/suspengine.py`](file:///home/piseratopo/Desktop/Projektoj/Stacking-Blocks/Backend/suspengine.py) (threading locks, packet delimiter framing) and implement Room Code lobby and matchmaking in [`Backend/main.py`](file:///home/piseratopo/Desktop/Projektoj/Stacking-Blocks/Backend/main.py).
- [x] **Step 4: Client Network Manager & Protocol Handlers**: Implement `obj_network_manager` using `ext_suspendee` to handle room creation, joining, piece sync, and attack routing.
- [ ] **Step 5: Opponent Board & Rendering**: Wire remote board mirroring via `obj_player_board` (`is_local = false`) to display opponent grid.
- [ ] **Step 6: UI & Polishing**: Build Room Code entry/display UI, countdown overlay, match-over victory popup, and rematch flow.
