FROM tomcat:8.0

COPY /var/jenkins_home/workspace/webapp@2/webapp/target/webapp.war /usr/local/tomcat/webapps/

EXPOSE 8080

CMD ["catalina.sh", "run"]
