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

if [ $(rpm -qa|grep -c python-neutronclient) -gt 0 ]; then
    echo python-neutronclient present
else
    echo Please install python-neutronclient
    exit 1
fi

#Create new project
echo Creating project "$newprojectname" with description "$newprojectdesc"
newprojectid=$(get_id openstack project create --description "$newprojectdesc" "$newprojectname")

#Add admin to newly created project to adjust security rules
echo Adding "$adminuser" to "$newprojectname" to set security group values
openstack role add --project $newprojectid --user $adminuser Member

#Adjust default security rules for new project
echo Setting correct security group rules
#openstack --os-project-name "$newprojectname" security group rule create --proto tcp --src-ip 0.0.0.0/0 --dst-port 1:65535 default # to allow all
#openstack --os-project-name "$newprojectname" security group rule create --proto tcp --src-ip ::/0 --dst-port 1:65535 default # to allow all
#openstack --os-project-name "$newprojectname" security group rule create --proto udp --src-ip 0.0.0.0/0 --dst-port 1:65535 default # to allow all
#openstack --os-project-name "$newprojectname" security group rule create --proto udp --src-ip ::/0 --dst-port 1:65535 default # to allow all
#openstack --os-project-name "$newprojectname" security group rule create --proto icmp --src-ip 0.0.0.0/0 --dst-port -1:-1 default # to allow all
#openstack --os-project-name "$newprojectname" security group rule create --proto icmp --src-ip ::/0 --dst-port -1:-1 default # to allow all
neutron --os-tenant-name "$newprojectname" security-group-rule-create --ethertype ipv4  --direction ingress default
neutron --os-tenant-name "$newprojectname" security-group-rule-create --ethertype ipv6  --direction ingress default

#Remove admin from newly created project
echo Removing "$adminuser" from "$newprojectname".
openstack role remove --project $newprojectid --user $adminuser Member

echo "New project has been created (hopefully), please check above output for any errors"
