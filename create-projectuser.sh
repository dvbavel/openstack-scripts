#!/bin/bash

length=$(($#-1))
userarray=${@:1:$length}
echo $userarray
projectname="${@: -1}"
echo $projectname

if [[ $# -eq 0 ]] ; then
    echo '================================================================================='
    echo 'Script usage: ./create-projectuser.sh "Users" "Project name"'
    echo '---------------------------------------------------------------------------------'
    echo 'Project Users		: The usernames that should be added to the project'
    echo 'Project Name          : The name of the project as it will appear in OpenStack'
    echo '================================================================================='
    exit 1
fi

if [ $(rpm -qa|grep -c python-openstackclient) -gt 0 ]; then
    echo python-openstackclient present
else
    echo Please install python-openstackclient
    exit 1
fi

#Create new project
echo Adding $userarray to $projectname
for i in $userarray; do
openstack role add --project "$projectname" --user "$i" Member
openstack role add --project "$projectname" --user "$i" heat_stack_owner
done

#echo New project has been created (hopefully), please check above output for any errors