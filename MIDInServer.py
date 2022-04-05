import socket, time
import mido
import mido.backends.rtmidi

conn = None

def main():
    global conn
    print(" " + "_"*30 + "\n|_____P3synth_MIDIn_Server_____|")
    print("Welcome! Warning: this is an unstable addon.\nFor detailed instructions, see the project's website.\n")

    HOST = "localhost"
    PORT = 7723

    for n, i in enumerate(mido.get_input_names()):
        print(f"{n} .. {i}")
    port_num = mido.get_input_names()[int(input("Which port to listen to? "))]

    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    print(f"\nSending to {HOST}:{PORT}...")
    print("Please run P3synth and activate MIDI In mode!", end="\r")

    s.bind((HOST, PORT))
    s.listen(10)
    conn, addr = s.accept()
    print("OK!" + " "*50, end="\n\n")

    with mido.open_input(port_num) as port:
        while True:
            msg = port.poll()
            if msg is not None:
                b = [str(x) for x in msg.bytes()]
                print("[*]", end="\r")
                try:
                    conn.send(f"{str(msg.channel)} {b[0]} {b[1]} {b[2]}\n".encode())
                except (AttributeError, IndexError):
                    continue
                except (BrokenPipeError, ConnectionResetError):
                    print("\nDisconnected!")
                    return

            else:
                time.sleep(0.01)
                print("[ ]", end="\r")


if __name__ == "__main__":
    try:
        main()
        if conn is not None:
            conn.close()

    except KeyboardInterrupt:
        if conn is not None:
            conn.send("goodbye".encode())
            conn.close()

    print("\nConnection closed.")
