import socket
import mido

HOST = "localhost"
PORT = 7726
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

s.bind((HOST, PORT))
s.listen(10)
conn, addr = s.accept()

with mido.open_input(mido.get_input_names()[1]) as port:
    while True:
        msg = port.poll()
        if msg is not None:
            b = [str(x) for x in msg.bytes()]
            try:
                conn.send(f"{str(msg.channel)} {b[0]} {b[1]} {b[2]}\n".encode())
            except (AttributeError, IndexError):
                continue
        '''
        if midi_in.poll():
            event = midi_in.read(1)
            conn.send((str(event[0][0]).replace("[", "").replace("]", "") + "\n").encode())
        '''

conn.close()
