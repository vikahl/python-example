"""Service entrypoint for python_project_example.

One alternative solution is to specify an entrpoint in setup.cfg and run the
service as a cli command. This needs to be modified if the service is started
with another command (e.g., gunicorn).
"""

import time

import python_project_example

for i in range(10):
    print(f"{i}. Service is running.")
    time.sleep(30)
