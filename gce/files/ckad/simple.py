#!/usr/bin/python
## Import the necessary modules
import time
import socket
## Use an ongoing while loop to generate output
while True :
## Set the hostname and the current date
  host = socket.gethostname()
  date = time.strftime("%Y-%m-%d %H:%M:%S")
  now = str(date)
  f = open("date.out", "a" )
  f.write(now + "\n")
  f.write(host + "\n")
  f.close()
  time.sleep(5)

  