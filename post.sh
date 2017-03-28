#!/bin/bash

hexo clean
hexo g
hexo -p 5000 server

read -p "Do you want to deploy it to the github? (y/n)" answer

# echo "Your answer is $answer."
if  [[ "$answer" = y* ]]
then 
    hexo d
    echo "Deploy hexo to github successfully!!"
fi


