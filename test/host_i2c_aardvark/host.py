import sys, os, time, array, signal
from aardvark_py import *

device_addr = 123

COMMAND_GET = 1
COMMAND_SET = 2

def make_command(direction, entity, address, payload_length, payload):
  c = []
  if direction == 'SET':
    c.append(COMMAND_SET)
  else:
    c.append(COMMAND_GET)
  c.append(entity & 0xFF)
  c.extend([(address >> 16) & 0xFF, (address >> 8) & 0xFF, address & 0xFF])
  c.append(payload_length & 0xFF)
  if direction == 'SET':
    c.extend(payload)
  return array('B', c)

num_commands = 0

def do_set_command(handle):
  # make a SET command for mic gain
  # use entity number to refer to Illusonic library as "client 0"
  # use property number to select INIT module, 0x4100
  # and mic gain parameter, 0x49 (ASCII 'I') --> 0x494100
  # send 8bit value of 1 as data
  global num_commands
  data = make_command('SET', 0, 0x494100, 1, [1])
  print '%u: send SET command:' % num_commands, ' '.join('{:02x}'.format(c) for c in data.tolist())
  aa_i2c_write(handle, device_addr, AA_I2C_NO_FLAGS, data)
  num_commands += 1

def do_get_command(handle):
  # make a GET command for diagnostics
  # use entity number to refer to Illusonic library as "client 0"
  # use address to select DIAG module, 0x4C00
  # and diagnostics parameter, 0x45 (ASCII 'E') --> 0x454C00
  # request 4 bytes back
  global num_commands
  data = make_command('GET', 0, 0x454C00, 4, None)
  print '%u: send GET command:' % num_commands, ' '.join('{:02x}'.format(c) for c in data.tolist())
  aa_i2c_write(handle, device_addr, AA_I2C_NO_FLAGS, data)
  (count, data) = aa_i2c_read(handle, device_addr, AA_I2C_NO_FLAGS, 4)
  print 'GET data returned:', ' '.join('{:02x}'.format(c) for c in data.tolist())
  num_commands += 1

def init_aardvark():
  port = 0
  bitrate_khz = 100
  bus_timeout_ms = 150
  handle = aa_open(port)
  if handle <= 0:
    print 'no device on port %d' % port
    print "error code = %d" % handle
    sys.exit(1)
  aa_configure(handle, AA_CONFIG_SPI_I2C)
  aa_i2c_pullup(handle, AA_I2C_PULLUP_BOTH)
  aa_i2c_bitrate(handle, bitrate_khz)
  aa_i2c_bus_timeout(handle, bus_timeout_ms)
  return handle

def cleanup_aardvark(handle):
  aa_close(handle)

done = False

def signal_handler(signum, frame):
  global done
  if signum == signal.SIGINT:
    done = True

handle = init_aardvark()

signal.signal(signal.SIGINT, signal_handler)

while not done:
  for i in range(4):
    if done:
      break
    do_set_command(handle)
    if not done:
      time.sleep(0.1)
    do_get_command(handle)
    if not done:
      time.sleep(1)

cleanup_aardvark(handle)
