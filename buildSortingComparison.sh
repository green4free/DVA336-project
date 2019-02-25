#!/usr/bin/env bash

cc -O3 -o sortingComparison sortingComparison.c

sudo chown root sortingComparison

sudo chmod u+s sortingComparison
