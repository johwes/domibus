#!/bin/bash
#
POD=""


oc new-app mysql-persistent -p MYSQL_USER=edelivery -p MYSQL_PASSWORD=edelivery -p MYSQL_ROOT_PASSWORD=edelivery -p MYSQL_DATABASE=domibus -p DATABASE_SERVICE_NAME=mysql -l app=domibus --name mysql

sleep 5

while :
do
  POD=$(oc get pod --field-selector=status.phase=Running -l name=mysql -o template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
  if [[ "$POD" != "" ]]; then
    break
  fi
  echo "db pod not running yet, sleeping 2 seconds"
  sleep 2
done

POD=$(oc get pod --field-selector=status.phase=Running -l name=mysql -o template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')


echo $POD

while :
do
  if  oc rsh $POD mysql -h $POD -u root --password=edelivery -e "show databases;" ; then
    break
  fi
  echo "db pod not running, sleeping 2 seconds"
  sleep 2
done


#configure database
oc rsh $POD mysql -h $POD -u root --password=edelivery -e "alter database domibus charset=utf8mb4 collate=utf8mb4_bin;"
oc rsh $POD mysql -h $POD -u root --password=edelivery domibus < ./dbfiles/mysql-4.2.7.ddl
oc rsh $POD mysql -h $POD -u root --password=edelivery domibus < ./dbfiles/mysql-4.2.7-data.ddl

#deploy domibus on jws
for x in $(ls k8s/*.yaml) ; do oc apply -f $x ; done


echo "Application is starting up, you can soon access it here: http://$(oc get route domibus --no-headers -o custom-columns=route:spec.host)$(oc get route domibus --no-headers -o custom-columns=route:spec.path)"
echo "Default user name and password is: admin 123456"

