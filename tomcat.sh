# Assigning a variable for tomcat download link
TOMURL="https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.37/bin/apache-tomcat-8.5.37.tar.gz"

# Install the dependencies
yum install java-1.8.0-openjdk -y
yum install git maven wget -y

# Switch to /temp directory 
cd /tmp/

# Download tomcat from the url link as tomcatbin.tar.gz
wget $TOMURL -O tomcatbin.tar.gz

# Assigning a variable to extract the tar.gz
# x-extract = is always required as the first argument when extracting an archive
# v-verbose = verbosely list files processed in background
# z-gzip = filter the archive through gzip
# f-file = option to specify the archive file for extracting
EXTOUT=`tar xvzf tomcatbin.tar.gz`

# Capturing the output of the extraction and taking the first line (which is the top level directory) and assign it to variable TOMDIR 
TOMDIR=`echo $EXTOUT | cut -d '/' -f1`

# Creating a user tomcat with nologin acccess
useradd --shell /sbin/nologin tomcat

# Sync the extracted (top-level)directory to /usr/local/tomcat8 path
# a-copy files recursively and preserve ownership of files when files are copied which is root in this case
# v-verbose
# z-gzip files
# h-human-readable format
rsync -avzh /tmp/$TOMDIR/ /usr/local/tomcat8/

# Change the user & group ownership of tomcat8 directory from root to tomcat  
chown -R tomcat.tomcat /usr/local/tomcat8

# Remove the default systemd setup of tomcat
rm -rf /etc/systemd/system/tomcat.service

# Setup systemd for tomcat to use systemctl commands for the tomcat service
cat <<EOT>> /etc/systemd/system/tomcat.service
[Unit]
Description=Tomcat
After=network.target

[Service]

User=tomcat
Group=tomcat

WorkingDirectory=/usr/local/tomcat8

#Environment=JRE_HOME=/usr/lib/jvm/jre
Environment=JAVA_HOME=/usr/lib/jvm/jre

Environment=CATALINA_PID=/var/tomcat/%i/run/tomcat.pid
Environment=CATALINA_HOME=/usr/local/tomcat8
Environment=CATALINE_BASE=/usr/local/tomcat8

ExecStart=/usr/local/tomcat8/bin/catalina.sh run
ExecStop=/usr/local/tomcat8/bin/shutdown.sh


RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target

EOT

# Start and Enable Tomcat service
systemctl daemon-reload
systemctl start tomcat
systemctl enable tomcat

# Clone the Project from Github to Buid and Deploy it to Tomcat server
git clone -b <branch-name> <repository-link>
cd <into-project-directory>

# Build Artifact using Maven
mvn install

# Deploy Artifcat to Tomcat server
# Stop tomcat server
systemctl stop tomcat

# Wait-time for next command
sleep 60

# Deleting the default web application of tomcat
rm -rf /usr/local/tomcat8/webapps/ROOT*

# Copying Artifact to tomcat server
cp target/<ARTIFACT.war> /usr/local/tomcat8/webapps/ROOT.war

# Start tomcat server
systemctl start tomcat

# Wait-time for next command
sleep 120

# Copy the applications.properties in /vagrant directory and then use below command
cp /vagrant/application.properties /usr/local/tomcat8/webapps/ROOT/WEB-INF/classes/application.properties

# Restart tomcat server
systemctl restart tomcat



