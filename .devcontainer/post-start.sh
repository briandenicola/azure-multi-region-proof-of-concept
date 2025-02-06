#!/bin/bash

# this runs each time the container starts

echo "$(date)    post-start start" >> ~/status
echo "$(date)    post-start complete" >> ~/status
