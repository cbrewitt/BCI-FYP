__author__ = 'cillian'

import emokit
import socket
import gevent
import struct
import datetime


def main():
    headset = None

    serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    serversocket.bind(('localhost', 7462))


    while True:

        # wait for client to connect
        print 'Waiting for client to connect...'
        serversocket.listen(1)
        (clientsocket, address) = serversocket.accept()
        print 'Client connected'

        try:

            # begin reading packets from headset
            print 'Connecting to headset...'
            headset = emokit.emotiv.Emotiv()
            gevent.spawn(headset.setup)
            gevent.sleep(1)

            print 'Receiving packets from headset...'
            sent = True
            # loop to send packets to client
            while sent:
                packet = headset.dequeue()

                # convert packet to byte array
                sensor_values = [int(packet.F3[0]),
                    int(packet.FC5[0]),
                    int(packet.AF3[0]),
                    int(packet.F7[0]),
                    int(packet.T7[0]),
                    int(packet.P7[0]),
                    int(packet.O1[0]),
                    int(packet.O2[0]),
                    int(packet.P8[0]),
                    int(packet.T8[0]),
                    int(packet.F8[0]),
                    int(packet.AF4[0]),
                    int(packet.FC6[0]),
                    int(packet.F4[0])]

                for x in range (len(sensor_values)):
                    sensor_values[x] -= 8192

                write_buffer = struct.pack('h' *len(sensor_values), *sensor_values)
                sent = clientsocket.send(write_buffer)

        except socket.error:
            print "Client disconnected"





if __name__ == "__main__":
    main()
