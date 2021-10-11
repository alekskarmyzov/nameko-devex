#!/bin/bash

# setting up cf environment
echo "Using Production Environment Variables locally..."

export AMQP_URI=amqp://guest:guest@3.64.162.116:5672
export POSTGRES_URI=postgresql://postgres:password@3.64.162.116:5432
export REDIS_URI=redis://3.64.162.116:6379

./run.sh $@ 