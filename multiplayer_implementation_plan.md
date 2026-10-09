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
   - The client manages a single **Local Board** (`obj_player_board` with `is_local = true`) and a dynamic array of **Remote Boards** (`remote_boards = []`).
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

## 2. Phase 1: Decoupling GameMaker Logic (Single-Board -> Multi-Board)

Currently, [obj_controller](file:///d:/Projektoj/Stacking-Blocks/Stacking%20Blocks/objects/obj_controller/Create_0.gml) and [scr_macro.gml](file:///d:/Projektoj/Stacking-Blocks/Stacking%20Blocks/scripts/scr_macro/scr_macro.gml) hardcode single-board coordinates and global references.

### 2.1 Parameterize Board Coordinates & Instances
Convert static macros into instance variables on `obj_player_board`:
- **Board Coordinates**:
  ```gml
  // In obj_player_board Create event
  is_local = true;
  player_id = "";             // Assigned by server (e.g. client socket ID)
  slot_index = 0;            // 0 = primary/left, 1..N = remote opponents
  
  // Board positioning
  grid_start_x = 280;
  grid_bottom_y = 1900;
  grid_width = 10;
  grid_height = 20;
  cell_size = CELL_SIZE;
  ```
- **Coordinate Conversion Functions**: Convert `grid_x_to_col`, `grid_y_to_row`, etc., into methods bound to `obj_player_board`:
  ```gml
  board_x_to_col = function(_x) { return round((_x - grid_start_x) / cell_size); };
  board_y_to_row = function(_y) { return round((grid_bottom_y - _y) / cell_size); };
  board_col_to_x = function(_c) { return grid_start_x + _c * cell_size; };
  board_row_to_y = function(_r) { return grid_bottom_y - _r * cell_size; };
  ```

### 2.2 Board Ownership for Shapes and Blocks
- When spawning a piece in `spawn_shape()`, assign `board_owner = self`:
  ```gml
  var _inst = instance_create_layer(_spawn_x, _spawn_y, "Blocks", obj_shape, {
      board_owner: self,
      shape_name: _shape_name,
      shape_data: _shape_props[$ _shape_name],
      sprite_index: _shape_props[$ _shape_name].display_spr,
      lock_spr: _shape_props[$ _shape_name].lock_spr,
      orientation: 0
  });
  ```
- In [obj_shape](file:///d:/Projektoj/Stacking-Blocks/Stacking%20Blocks/objects/obj_shape/Create_0.gml) and [obj_block](file:///d:/Projektoj/Stacking-Blocks/Stacking%20Blocks/objects/obj_block/Create_0.gml):
  - Replace `obj_controller.grid_set()` -> `board_owner.grid_set()`.
  - Replace `obj_controller.clear_lines()` -> `board_owner.clear_lines()`.
  - Replace global border collision with board-scoped boundary checks:
    ```gml
    kick_in_bounds = function(_kx, _ky = 0) {
        return (bbox_left + _kx >= board_owner.grid_start_x) &&
               (bbox_right + _kx <= board_owner.grid_start_x + board_owner.grid_width * CELL_SIZE) &&
               (bbox_bottom + _ky <= board_owner.grid_bottom_y);
    };
    ```

---

## 3. Phase 2: Versus Mechanics & Garbage System

### 3.1 Line Clear Attack Table
When `clear_lines()` completes in `obj_player_board`:
| Cleared Lines | Base Garbage | Combo Bonus | Back-to-Back Bonus |
|---|---|---|---|
| 1 Line (Single) | 0 | +combo_count | 0 |
| 2 Lines (Double) | 1 | +combo_count | 0 |
| 3 Lines (Triple) | 2 | +combo_count | 0 |
| 4 Lines (Tetris) | 4 | +combo_count | +1 |
| All Clear (Empty Board) | 10 | Instant burst | 0 |

### 3.2 Incoming Garbage Meter & Cancellation
1. **Garbage Countering**: Incoming garbage enters `pending_garbage = []`. If the player clears lines before the garbage rises, their attack cancels out incoming garbage first (`pending_lines -= attack_lines`).
2. **Rising from the Bottom**: Remaining incoming lines push existing locked blocks upward. A random empty column (hole) is chosen per attack to create counter-play opportunities.
3. **Knockout / Top-Out**: If a block locks above row 20 or an incoming piece cannot spawn, trigger `on_player_ko()`.

---

## 4. Phase 3: Python Backend Architecture (`Backend/`)

### 4.1 Server Hardening ([suspengine.py](file:///d:/Projektoj/Stacking-Blocks/Backend/suspengine.py))
- **Thread Safety**: Add `threading.Lock()` to guard `clientlist`, `userdata`, and room mappings.
- **Packet Delimiter Splitting**: Refactor buffer parsing in `handleclient` to prevent fragmented JSON issues.
- **Clean Disconnects**: Emit room teardown/opponent notification if a socket disconnects abruptly.

### 4.2 Room System & State Machine ([main.py](file:///d:/Projektoj/Stacking-Blocks/Backend/main.py))
Implement a scalable room management architecture:

```python
class Room:
    def __init__(self, code, max_players=2):
        self.code = code
        self.max_players = max_players
        self.players = {}         # client_socket -> {"ready": bool, "alive": bool, "name": str}
        self.state = "LOBBY"      # "LOBBY", "COUNTDOWN", "IN_GAME", "GAME_OVER"
        self.match_seed = 0
```

- **Room Code Generator**: Random 4 uppercase characters (e.g., `random.choices(string.ascii_uppercase, k=4)`), ensuring uniqueness.
- **Match Lifecycle**:
  - `room_create`: Host creates room, receives 4-letter code.
  - `room_join`: Second player (and future players) enter code.
  - `room_ready`: When all players toggle ready, trigger 3-second countdown.
  - `match_start`: Distribute synchronized `match_seed` so all clients generate the exact same piece sequence.
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

## 6. Phase 5: Client-Side Implementation in GameMaker

### 6.1 `obj_network_manager`
- Persistent object initialized in the title room.
- Manages socket connection to `127.0.0.1:5001` (or remote IP).
- Binds event callbacks via `network_listen()`.
- Dispatches state updates to local and remote board objects.

### 6.2 Remote Board Representation (`obj_remote_board`)
- Renders at `x = 920` (right side of viewport).
- Holds an independent `play_grid` and renders locked blocks with autotiled sprites.
- Listens to `piece_sync` to render the opponent's active falling piece with smooth interpolation.
- Extensible: multiple `obj_remote_board` instances can be instantiated and arranged dynamically for 1 vs many.

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

- [ ] **Step 1: Board Refactoring**: Decouple [obj_controller](file:///d:/Projektoj/Stacking-Blocks/Stacking%20Blocks/objects/obj_controller/Create_0.gml) and [scr_macro.gml](file:///d:/Projektoj/Stacking-Blocks/Stacking%20Blocks/scripts/scr_macro/scr_macro.gml) into self-contained board instances with parameterized coordinates.
- [ ] **Step 2: Ownership & Garbage Engine**: Link [obj_shape](file:///d:/Projektoj/Stacking-Blocks/Stacking%20Blocks/objects/obj_shape/Create_0.gml) and [obj_block](file:///d:/Projektoj/Stacking-Blocks/Stacking%20Blocks/objects/obj_block/Create_0.gml) to `board_owner`; build the garbage generation and line push mechanism.
- [ ] **Step 3: Backend Room System**: Harden [Backend/suspengine.py](file:///d:/Projektoj/Stacking-Blocks/Backend/suspengine.py) (threading locks) and implement the Room Code lobby and matchmaking state machine in [Backend/main.py](file:///d:/Projektoj/Stacking-Blocks/Backend/main.py).
- [ ] **Step 4: Client Network Manager & Protocol Handlers**: Implement `obj_network_manager` using [ext_suspendee](file:///d:/Projektoj/Stacking-Blocks/Stacking%20Blocks/extensions/ext_suspendee) to handle room creation, joining, piece sync, and attack routing.
- [ ] **Step 5: Opponent Board & Rendering**: Build `obj_remote_board` to mirror opponent grid and falling piece.
- [ ] **Step 6: UI & Polishing**: Build the Room Code entry/display UI, countdown overlay, match-over victory popup, and rematch flow.
