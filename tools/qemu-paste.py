#!/usr/bin/env python3
"""Type ASCII text into a running QEMU guest via its QMP keyboard interface."""
import argparse
import json
from pathlib import Path
import queue
import socket
import threading
import time


def key_events(char):
    plain = dict(zip('`-=[]\\;\',./',
                     ['grave_accent', 'minus', 'equal', 'bracket_left',
                      'bracket_right', 'backslash', 'semicolon', 'apostrophe',
                      'comma', 'dot', 'slash']))
    shifted = dict(zip('~!@#$%^&*()_+{}|:"<>?', '`1234567890-=[]\\;\',./'))
    shift = char.isascii() and char.isupper() or char in shifted
    base = shifted.get(char, char.lower())
    if base in 'abcdefghijklmnopqrstuvwxyz0123456789':
        code = base
    elif base in plain:
        code = plain[base]
    elif base in (' ', '\t', '\n'):
        code = {' ': 'spc', '\t': 'tab', '\n': 'ret'}[base]
    else:
        raise ValueError(f'Unsupported character: {char!r}; use ASCII text')
    def event(key, down):
        return {'type': 'key', 'data': {'down': down,
                'key': {'type': 'qcode', 'data': key}}}
    keys = ['shift', code] if shift else [code]
    return [event(key, True) for key in keys] + [event(key, False) for key in reversed(keys)]


def type_text(path, text, delay=0.03):
    text = text.replace('\r\n', '\n').replace('\r', '\n')
    events = [key_events(char) for char in text]  # Validate before typing anything.
    with socket.socket(socket.AF_UNIX) as sock:
        sock.settimeout(5)
        sock.connect(str(path))
        with sock.makefile('rwb', buffering=0) as stream:
            def reply():
                line = stream.readline()
                if not line:
                    raise RuntimeError('QEMU closed QMP')
                return json.loads(line)
            if 'QMP' not in reply():
                raise RuntimeError('Expected QMP greeting')
            def command(name, arguments=None):
                message = {'execute': name}
                if arguments is not None:
                    message['arguments'] = arguments
                stream.write((json.dumps(message) + '\n').encode())
                while True:
                    response = reply()
                    if 'error' in response:
                        raise RuntimeError(response['error'])
                    if 'return' in response:
                        return response['return']
            command('qmp_capabilities')
            if command('query-status')['status'] != 'running':
                raise RuntimeError('QEMU must be running before text is typed')
            for keys in events:
                command('input-send-event', {'events': keys})
                time.sleep(delay)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--socket', type=Path, required=True, help='QEMU QMP Unix socket')
    inputs = parser.add_mutually_exclusive_group()
    inputs.add_argument('--text', help='Text to type; does not append Enter')
    inputs.add_argument('--file', type=Path, help='UTF-8 file to type, including newlines')
    args = parser.parse_args()
    if args.text is not None or args.file is not None:
        type_text(args.socket, args.text if args.text is not None else args.file.read_text())
        return

    import tkinter as tk
    from tkinter import messagebox
    root = tk.Tk()
    root.title('Paste into TempleOS QEMU')
    tk.Label(root, text='Paste here with Ctrl+V, then click Type into QEMU.\n'
             'Newlines press Enter. At the console, they execute commands.').pack(padx=12, pady=8)
    editor = tk.Text(root, width=76, height=12, undo=True)
    editor.pack(padx=12, pady=4)
    status = tk.StringVar(value='Ready. No Enter is appended automatically.')
    events = queue.Queue()
    def send():
        text = editor.get('1.0', 'end-1c')
        if not text:
            return
        button.config(state='disabled')
        status.set('Typing into QEMU…')
        def worker():
            try:
                type_text(args.socket, text)
                events.put(None)
            except Exception as exc:
                events.put(str(exc))
        threading.Thread(target=worker, daemon=True).start()
    def poll():
        try:
            error = events.get_nowait()
        except queue.Empty:
            pass
        else:
            button.config(state='normal')
            status.set('Typing failed; some text may have arrived.' if error else
                       'Typed. Return to QEMU to review the text or press Enter.')
            if error:
                messagebox.showerror('QEMU paste', error)
        root.after(100, poll)
    button = tk.Button(root, text='Type into QEMU', command=send)
    button.pack(pady=8)
    tk.Label(root, textvariable=status).pack(padx=12, pady=6)
    editor.focus_set()
    poll()
    root.mainloop()


if __name__ == '__main__':
    main()
