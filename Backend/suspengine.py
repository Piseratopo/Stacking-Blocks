import socket
import threading
import json
import traceback

userdata = {}
clientlist = []
userevents = {}
use = {}
prev = {}
limit = False
defaultlimit = 4096
debug = False
splitter = "[{//V//}]"
lock = threading.RLock()


def savevariable(name, data, client):
    global userdata
    with lock:
        if str(client) not in userdata:
            userdata[str(client)] = {}
        userdata[str(client)][name] = data


def callvariable(name, client):
    global userdata
    with lock:
        if str(client) in userdata and name in userdata[str(client)]:
            return userdata[str(client)][name]
        return None


def callvariablelist(name, data):
    global userdata
    global clientlist
    templist = []
    with lock:
        for c in clientlist:
            if str(c) in userdata and name in userdata[str(c)]:
                if userdata[str(c)][name] == data:
                    templist.append(c)
    return templist


def addfunc(event, func):
    global use
    with lock:
        use[event] = func


def channel(args1):
    def otherchannel(function):
        global use
        with lock:
            use[args1] = function
        return function

    return otherchannel


def emit(event, message, client):
    global splitter
    tempdata = {
        event: message,
        'identify': event
    }
    encoded = (json.dumps(tempdata) + splitter).encode('utf-8')
    try:
        client.sendall(encoded)
        return True
    except Exception as e:
        if debug:
            print(f"[suspengine] emit failed to {client}: {e}")
        return False


def broadcast(event, message, exclude=None):
    global clientlist
    with lock:
        targets = list(clientlist)
    for c in targets:
        if exclude is not None and c == exclude:
            continue
        emit(event, message, c)


def disconnect(client):
    try:
        client.close()
    except Exception:
        pass


def _cleanup_client(c, addr):
    global clientlist, userdata, prev, use
    with lock:
        if c in clientlist:
            clientlist.remove(c)
        userdata.pop(str(c), None)
        prev.pop(str(c), None)
    
    try:
        c.close()
    except Exception:
        pass

    if 'disconnect' in use:
        try:
            use['disconnect'](c, addr)
        except Exception as e:
            if debug:
                print(f"[suspengine] disconnect hook error: {e}")


def handleclient(c, addr):
    global clientlist, userevents, splitter, use, prev, limit, defaultlimit, debug
    while True:
        try:
            data = c.recv(defaultlimit)
            if not data:
                _cleanup_client(c, addr)
                break
        except Exception:
            _cleanup_client(c, addr)
            break

        packets = []
        try:
            decoded_chunk = data.decode('utf-8', errors='ignore')
            with lock:
                buffer = prev.get(str(c), "") + decoded_chunk
                parts = buffer.split(splitter)
                if not limit:
                    prev[str(c)] = parts[-1]
                    packets = parts[:-1]
                else:
                    packets = [p for p in parts if p]
                    prev[str(c)] = ""
        except Exception as e:
            if debug:
                print(f"[suspengine] Framing error: {e}")
            continue

        for pkt in packets:
            if not pkt.strip():
                continue
            try:
                tempdat = json.loads(pkt)
            except Exception as e:
                if debug:
                    print(f"[suspengine] JSON parse error: {e} in '{pkt}'")
                continue

            for key, val in tempdat.items():
                if key == 'identify':
                    continue
                func = None
                with lock:
                    if key in use:
                        func = use[key]
                if func:
                    threading.Thread(target=func, args=[c, addr, val], daemon=True).start()


def server(host, port, **kwargs):
    global limit, debug, defaultlimit, clientlist, use, userdata, prev
    slots = 20

    for k, v in kwargs.items():
        if k == 'debug':
            debug = v
            if debug:
                print('Debug Enabled')
        elif k == 'slots':
            slots = v
            if debug:
                print(f'Your server can take {slots} connections.')
        elif k == 'limit':
            limit = v
            if debug and not limit:
                print('You have removed the limit on how big your packets can be')
        elif k == 'defaultlimit':
            defaultlimit = v
            if debug:
                print(f'Your limit to how big a packet can be is {defaultlimit} bytes.')

    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind((host, port))
    s.listen(slots)

    print(f"[suspengine] Server listening on {host}:{port}...")

    while True:
        try:
            c, addr = s.accept()
            with lock:
                clientlist.append(c)
                userdata[str(c)] = {}
                prev[str(c)] = ""
            print(f"[suspengine] {addr[0]} connected from port {addr[1]}")
            threading.Thread(target=handleclient, args=[c, addr], daemon=True).start()
            if 'connect' in use:
                threading.Thread(target=use['connect'], args=[c, addr], daemon=True).start()
        except Exception as e:
            if debug:
                print(f"[suspengine] accept loop error: {e}")
