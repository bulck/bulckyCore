#!/usr/bin/env python
# coding: utf-8

import socket

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect(("localhost", 6028))

s.send(bytes("Patahouette", 'UTF-8'))

s.close()
