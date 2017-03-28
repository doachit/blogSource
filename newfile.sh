#!/bin/bash

#read the category file to list all the categories
FILENAME=category
num=0
echo "The existing categories :"
for line in `cat $FILENAME `
do
    let num++
    echo $num ": "$line
done

#whether to create a new category?
read -p "Do you want to creat a new category? (y/n)" answer

# echo "Your answer is $answer."
if  [[ "$answer" = y* ]]
then 
    read -t 30 -p "input a new categorie :" newcat
    echo "The categorie is : $newcat"
    echo "$newcat" >> $FILENAME
else
    read -p  "Please input the sequence number :" number
    selected=$(sed -n "$number p" category)
    echo "$selected"
fi

#creat new file and auto-input the category
read -p "input the new post name : " postname
postname="./source/_posts/$postname.md"
newline="categories: $selected"
sed -i '/categories/d' $postname
sed -i "/date/a $newline" $postname
cat style >> $postname

#done
echo "New file $postname.md has created successfully!!!"