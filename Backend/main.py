import suspengine
import random
import string
import threading
import time

# Active room dictionaries (guarded by lock)
rooms_by_code = {}        # code (str) -> Room
client_to_room = {}       # client_socket -> Room
room_lock = threading.RLock()


def generate_room_code():
    chars = "ABCDEFGHJKLMNPQRSTUVWXYZ"  # Omitting 'I' and 'O' to avoid visual confusion
    for _ in range(1000):
        code = "".join(random.choices(chars, k=4))
        if code not in rooms_by_code:
            return code
    return "".join(random.choices(chars, k=5))


class Room:
    def __init__(self, code, host_socket, max_players=2):
        self.code = code
        self.host_socket = host_socket
        self.max_players = max_players
        self.state = "LOBBY"  # "LOBBY", "COUNTDOWN", "IN_GAME", "GAME_OVER"
        self.players = {}     # client_socket -> dict of player info
        self.match_seed = 0
        self.countdown_timer = None

    def get_available_slot(self):
        used_slots = {p["slot"] for p in self.players.values()}
        for slot in range(self.max_players):
            if slot not in used_slots:
                return slot
        return len(used_slots)

    def add_player(self, client, name=None):
        slot = self.get_available_slot()
        if not name or not str(name).strip():
            name = f"Player {slot + 1}"
        player_info = {
            "slot": slot,
            "name": str(name).strip(),
            "ready": False,
            "alive": True,
            "score": 0,
            "lines_cleared": 0
        }
        self.players[client] = player_info
        return player_info

    def remove_player(self, client):
        self.cancel_countdown()
        return self.players.pop(client, None)

    def is_full(self):
        return len(self.players) >= self.max_players

    def is_empty(self):
        return len(self.players) == 0

    def get_player(self, client):
        return self.players.get(client)

    def get_player_list(self):
        return [
            {
                "slot": p["slot"],
                "name": p["name"],
                "ready": p["ready"],
                "alive": p["alive"],
                "score": p["score"],
                "lines_cleared": p["lines_cleared"]
            }
            for p in self.players.values()
        ]

    def all_ready(self):
        if len(self.players) < 2:
            return False
        return all(p["ready"] for p in self.players.values())

    def broadcast(self, event, data, exclude=None):
        for client in list(self.players.keys()):
            if exclude is not None and client == exclude:
                continue
            suspengine.emit(event, data, client)

    def cancel_countdown(self):
        if self.countdown_timer and self.countdown_timer.is_alive():
            self.countdown_timer.cancel()
        self.countdown_timer = None
        if self.state == "COUNTDOWN":
            self.state = "LOBBY"

    def start_countdown(self, on_start_cb):
        self.cancel_countdown()
        self.state = "COUNTDOWN"
        self.match_seed = random.randint(100000, 999999)
        self.broadcast("countdown_start", {
            "seconds": 3,
            "seed": self.match_seed
        })

        def _finish():
            with room_lock:
                if self.state == "COUNTDOWN" and self.all_ready():
                    self.state = "IN_GAME"
                    for p in self.players.values():
                        p["alive"] = True
                    on_start_cb(self)

        self.countdown_timer = threading.Timer(3.0, _finish)
        self.countdown_timer.daemon = True
        self.countdown_timer.start()

    def handle_attack(self, sender_client, lines, hole_col, target_slot=None):
        sender = self.players.get(sender_client)
        if not sender:
            return

        targets = []
        if target_slot is not None:
            # 1 vs Many targeted attack
            for c, p in self.players.items():
                if p["slot"] == target_slot and p["alive"] and c != sender_client:
                    targets.append(c)
        else:
            # 1v1 direct attack or random alive opponent
            alive_opponents = [c for c, p in self.players.items() if c != sender_client and p["alive"]]
            if alive_opponents:
                # In 1v1 this is exactly the single opponent
                targets = [random.choice(alive_opponents)]

        attack_data = {
            "from_slot": sender["slot"],
            "lines": int(lines),
            "hole_col": int(hole_col)
        }

        for target_client in targets:
            suspengine.emit("attack_receive", attack_data, target_client)

    def handle_ko(self, client):
        loser = self.players.get(client)
        if not loser:
            return

        loser["alive"] = False
        self.broadcast("player_ko", {"slot": loser["slot"], "name": loser["name"]})

        alive_players = [p for p in self.players.values() if p["alive"]]
        if len(alive_players) <= 1:
            winner = alive_players[0] if alive_players else loser
            self.state = "GAME_OVER"
            self.broadcast("match_over", {
                "winner_slot": winner["slot"],
                "winner_name": winner["name"],
                "reason": "ko"
            })
            # Reset to lobby state for rematch
            self.state = "LOBBY"
            for p in self.players.values():
                p["ready"] = False
            self.broadcast("room_update", {
                "code": self.code,
                "players": self.get_player_list(),
                "state": self.state
            })


# =====================================================================
# Networking Event Handlers
# =====================================================================

@suspengine.channel("room_create")
def on_room_create(client, addr, data):
    max_players = 2
    player_name = "Player 1"

    if isinstance(data, dict):
        max_players = int(data.get("max_players", 2))
        player_name = data.get("name", "Player 1")

    with room_lock:
        # If client already in a room, leave it first
        if client in client_to_room:
            _cleanup_player_room(client)

        code = generate_room_code()
        room = Room(code, client, max_players=max_players)
        p_info = room.add_player(client, player_name)

        rooms_by_code[code] = room
        client_to_room[client] = room

        print(f"[Room] Created {code} by {player_name} ({addr[0]})")

        suspengine.emit("room_created", {
            "code": code,
            "slot": p_info["slot"],
            "max_players": room.max_players,
            "name": p_info["name"]
        }, client)

        room.broadcast("room_update", {
            "code": code,
            "players": room.get_player_list(),
            "state": room.state
        })


@suspengine.channel("room_join")
def on_room_join(client, addr, data):
    if not isinstance(data, dict):
        suspengine.emit("room_error", {"message": "Invalid join data"}, client)
        return

    raw_code = str(data.get("code", "")).strip().upper()
    player_name = data.get("name", "Player 2")

    with room_lock:
        if raw_code not in rooms_by_code:
            suspengine.emit("room_error", {"message": f"Room '{raw_code}' not found"}, client)
            return

        room = rooms_by_code[raw_code]

        if room.is_full():
            suspengine.emit("room_error", {"message": "Room is full"}, client)
            return

        if room.state == "IN_GAME":
            suspengine.emit("room_error", {"message": "Match already in progress"}, client)
            return

        # If client already in another room, leave it first
        if client in client_to_room:
            _cleanup_player_room(client)

        p_info = room.add_player(client, player_name)
        client_to_room[client] = room

        print(f"[Room] {p_info['name']} joined {room.code} ({addr[0]})")

        suspengine.emit("room_joined", {
            "code": room.code,
            "slot": p_info["slot"],
            "max_players": room.max_players,
            "name": p_info["name"]
        }, client)

        room.broadcast("room_update", {
            "code": room.code,
            "players": room.get_player_list(),
            "state": room.state
        })


@suspengine.channel("player_ready")
def on_player_ready(client, addr, data):
    with room_lock:
        room = client_to_room.get(client)
        if not room:
            return

        p_info = room.get_player(client)
        if not p_info:
            return

        if isinstance(data, dict) and "ready" in data:
            p_info["ready"] = bool(data["ready"])
        else:
            p_info["ready"] = not p_info["ready"]

        # Cancel countdown if someone unreadies
        if not p_info["ready"] and room.state == "COUNTDOWN":
            room.cancel_countdown()

        room.broadcast("room_update", {
            "code": room.code,
            "players": room.get_player_list(),
            "state": room.state
        })

        if room.all_ready() and room.state == "LOBBY":
            def _on_match_start(r):
                print(f"[Room] Match starting in {r.code} with seed {r.match_seed}")
                r.broadcast("match_start", {
                    "seed": r.match_seed,
                    "player_count": len(r.players)
                })

            room.start_countdown(_on_match_start)


@suspengine.channel("piece_sync")
def on_piece_sync(client, addr, data):
    with room_lock:
        room = client_to_room.get(client)
        if not room or room.state != "IN_GAME":
            return
        p_info = room.get_player(client)
        if not p_info or not isinstance(data, dict):
            return

        payload = dict(data)
        payload["slot"] = p_info["slot"]
        room.broadcast("piece_sync", payload, exclude=client)


@suspengine.channel("piece_locked")
def on_piece_locked(client, addr, data):
    with room_lock:
        room = client_to_room.get(client)
        if not room or room.state != "IN_GAME":
            return
        p_info = room.get_player(client)
        if not p_info or not isinstance(data, dict):
            return

        payload = dict(data)
        payload["slot"] = p_info["slot"]
        if "lines_cleared" in payload:
            p_info["lines_cleared"] += int(payload["lines_cleared"])

        room.broadcast("piece_locked", payload, exclude=client)


@suspengine.channel("attack_send")
def on_attack_send(client, addr, data):
    if not isinstance(data, dict):
        return
    lines = data.get("lines", 0)
    hole_col = data.get("hole_col", 0)
    target_slot = data.get("target_slot", None)

    with room_lock:
        room = client_to_room.get(client)
        if not room or room.state != "IN_GAME":
            return
        room.handle_attack(client, lines, hole_col, target_slot)


@suspengine.channel("player_ko")
def on_player_ko(client, addr, data):
    with room_lock:
        room = client_to_room.get(client)
        if not room or room.state != "IN_GAME":
            return
        room.handle_ko(client)


@suspengine.channel("room_leave")
def on_room_leave(client, addr, data):
    with room_lock:
        _cleanup_player_room(client)


@suspengine.channel("ping")
def on_ping(client, addr, data):
    client_time = data.get("client_time", 0) if isinstance(data, dict) else 0
    suspengine.emit("pong", {
        "client_time": client_time,
        "server_time": time.time()
    }, client)


# =====================================================================
# Connection Lifecycle Cleanups
# =====================================================================

def _cleanup_player_room(client):
    room = client_to_room.pop(client, None)
    if not room:
        return

    p_info = room.remove_player(client)
    if p_info:
        print(f"[Room] {p_info['name']} left {room.code}")

    if room.is_empty():
        print(f"[Room] Destroyed empty room {room.code}")
        rooms_by_code.pop(room.code, None)
    else:
        # If match was in progress, remaining player wins by forfeit
        if room.state == "IN_GAME":
            alive_players = [p for p in room.players.values() if p["alive"]]
            if len(alive_players) == 1:
                winner = alive_players[0]
                room.state = "LOBBY"
                for p in room.players.values():
                    p["ready"] = False
                room.broadcast("match_over", {
                    "winner_slot": winner["slot"],
                    "winner_name": winner["name"],
                    "reason": "opponent_disconnected"
                })

        room.broadcast("room_update", {
            "code": room.code,
            "players": room.get_player_list(),
            "state": room.state
        })


@suspengine.channel("connect")
def on_connect(client, addr):
    print(f"[Server] Handshake ready for {addr[0]}:{addr[1]}")


@suspengine.channel("disconnect")
def on_disconnect(client, addr):
    print(f"[Server] Client disconnected: {addr[0]}:{addr[1]}")
    with room_lock:
        _cleanup_player_room(client)


# =====================================================================
# Main Server Entrypoint
# =====================================================================

if __name__ == "__main__":
    HOST = "0.0.0.0"
    PORT = 5001
    print(f"Starting Stacking Blocks Multiplayer Backend on {HOST}:{PORT}")
    suspengine.server(HOST, PORT, debug=True, slots=100)
