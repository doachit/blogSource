#!/bin/bash

hexo clean
hexo g



read -p "Do you want to deploy it and update all changes to the github? (y/n)" answer

# echo "Your answer is $answer."
if  [[ "$answer" = y* ]]
then 
    #push the new file to the github!!!
    git add *
    git commit -m "update the source file"
    git push origin master

    echo "Update the source file to github successfully!!!"
    
    hexo d
    echo "Deploy hexo to website successfully!!"
fi


