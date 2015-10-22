__author__ = 'cillian'

import emokit
import socket
import gevent
import struct


def main():
    headset = None

    serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    serversocket.bind('localhost', 7462)


    while True:

        # wait for client to connect
        serversocket.listen(1)
        (clientsocket, address) = serversocket.accept()

        try:
            # begin reading packets from headset
            headset = emokit.emotiv.Emotiv()
            gevent.spawn(headset.setup)
            gevent.sleep(1)

            sent = True
            # loop to send packets to client
            while sent:
                packet = headset.dequeue()

                # convert packet to byte array
                sensor_values = [packet.F3,
                    packet.FC5,
                    packet.AF3,
                    packet.F7,
                    packet.T7,
                    packet.P7,
                    packet.O1,
                    packet.O2,
                    packet.P8,
                    packet.T8,
                    packet.F8,
                    packet.AF4,
                    packet.FC6,
                    packet.F4]

                write_buffer = struct.pack('H' *len(sensor_values), *sensor_values)
                sent = clientsocket.send(write_buffer)
        finally:
            headset.close()

if __name__ == "__main__":
    main()
