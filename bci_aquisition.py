__author__ = 'cillian'

import emokit
import socket
import gevent


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
                sensor_values = bytearray()
                for sensor in packet.sensors:
                    sensor_values.append(sensor['value'])

                sent = clientsocket.send(sensor_values)
        finally:
            headset.close()

if __name__ == "__main__":
    main()
