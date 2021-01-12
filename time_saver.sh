#!/bin/bash
now=$(date)

git status 
git add .
git commit -m ''"$now"''

