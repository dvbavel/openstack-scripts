#!/bin/bash

length=$(($#-1))
userarray=${@:1:$length}
echo $userarray
projectname="${@: -1}"
echo $projectname

if [[ $# -ne 2 ]] ; then
    echo '================================================================================='
    echo 'Script usage: ./create-projectuser.sh "Users" "Project name"'
    echo '---------------------------------------------------------------------------------'
    echo 'Project Users		: The usernames that should be added to the project'
    echo 'Project Name          : The name of the project as it will appear in OpenStack'
    echo '================================================================================='
    exit 1
fi

#Check for script requirements
for osvar in OS_AUTH_URL OS_USERNAME OS_PASSWORD ; do
    if [ -n "${!osvar:-}" ] ; then
        echo "$osvar is set"
    else
        echo "$osvar is not set, please source your openrc file"
        exit 1
    fi
done

if [ $(rpm -qa|grep -c python-openstackclient) -gt 0 ]; then
    echo python-openstackclient present
else
    echo -e "[\e[1;31mERROR\e[0m] Please install python-openstackclient"
    echo "An error did occur during adding the project, script halted"
    exit 0
fi

#Create new project
echo Adding $userarray to $projectname
for i in $userarray; do
openstack role add --project "$projectname" --user "$i" Member
openstack role add --project "$projectname" --user "$i" heat_stack_owner
done

echo "New users have been added (hopefully) to there project"
