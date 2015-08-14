#!/bin/bash
newprojectname="$1"
newprojectdesc="$2"
floatingipquota="$3"
adminuser=admin

if [[ $# -lt 2 ]] ; then
    echo '=========================================================================================='
    echo 'Script usage: ./create-project.sh "Project Name" "Project Description" "Floating IP quota'
    echo '------------------------------------------------------------------------------------------'
    echo 'Project Name         : The name of the project as it will appear in OpenStack'
    echo 'Project Description  : Understandable Description of the project'
    echo 'Floating ip quota    : Quota for floating ip (not required)'
    echo '=========================================================================================='
    exit 1
fi

function get_id () {
    echo `"$@" | awk '/ id / { print $4 }'`
}

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

if [ $(rpm -qa|grep -c python-neutronclient) -gt 0 ]; then
    echo python-neutronclient present
else
    echo -e "[\e[1;31mERROR\e[0m] Please install python-neutronclient"
    echo "An error did occur during adding the project, script halted"
    exit 0
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

if [[ $3 -ne 0 ]] ; then
    echo setting Floating ip quota to "$floatingipquota"
    neutron quota-update --tenant_id "$newprojectid" --floatingip "$floatingipquota"
    echo "creating Floating IPs for new project"
    for n in $(seq $floatingipquota); do
        openstack --os-project-name "$newprojectname" floating ip create
    done
else
    echo Setting floating ip quota to 0
    neutron quota-update --tenant_id "$newprojectid" --floatingip 0
fi

#Remove admin from newly created project
echo Removing "$adminuser" from "$newprojectname".
openstack role remove --project $newprojectid --user $adminuser Member

echo "New project has been created (hopefully), please check above output for any errors"
