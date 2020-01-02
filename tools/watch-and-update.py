"""
Watch the upstream repositories for changes, and rebuild the image when there are any.
Optionally, also update running containers on docker-compose.

Before running this, install the dependencies: `pip install -r updates/requirements.txt`.

It requires Python 3.6 or newer.
"""
import sys
from updater import main

if sys.version_info.major != 3:
  print('Updater is only tested in Python 3.')
  sys.exit(1)
if sys.version_info.minor < 6:
  print('Updater needs Python 3.6 or newer.')
  sys.exit(1)

main()
