# Zig package for rcutils

This provides a zig package for the rcutils project.
This currently targets zig 0.12 and ROS Iron.

Note that rcutils depends on the python package [empy](http://www.alcyone.com/software/empy/) to generate logging macros.
Therefore this build has a python generation step.
All python dependencies appear to be cross platform.

## Dependencies
 - Python
 - empy (tested with version 3.3.4)

TODO The python dependency could easily be removed by creating a version of the rcutils repo with the generation already done.
Less easily would be adding the Python interpreter as a zig run dependency since this package exists: https://github.com/allyourcodebase/cpython/tree/main  

https://github.com/ros2/rcutils/tree/iron
