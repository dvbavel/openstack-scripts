#!/bin/bash
newprojectname="$1"
newprojectdesc="$2"
adminuser=admin

if [[ $# -eq 0 ]] ; then
    echo '================================================================================='
    echo 'Script usage: ./create-project.sh "Project Name" "Project Description"'
    echo '---------------------------------------------------------------------------------'
    echo 'Project Description  : Understable Description of the project'
    echo 'Project Name         : The name of the project as it will appear in OpenStack'
    echo '================================================================================='
    exit 1
fi

function get_id () {
    echo `"$@" | awk '/ id / { print $4 }'`
}

if [ $(rpm -qa|grep -c python-openstackclient) -gt 0 ]; then
    echo python-openstackclient present
else
    echo Please install python-openstackclient
    exit 1
fi

#Create new project
newprojectid=$(get_id openstack project create --description "$newprojectdesc" "$newprojectname")

#Add admin to newly created project to adjust security rules
openstack role add --project $newprojectid --user $adminuser Member

#Adjust default security rules for new project
openstack --os-project-name "$newprojectname" security group rule create --proto tcp --src-ip 0.0.0.0/0 --dst-port 1:65535 default # to allow all TCP
openstack --os-project-name "$newprojectname" security group rule create --proto udp --src-ip 0.0.0.0/0 --dst-port 1:65535 default # to allow all UDP

#Remove admin from newly created projec
openstack role remove --project $newprojectid --user $adminuser Member
