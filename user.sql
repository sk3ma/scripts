CREATE DATABASE myproject;
CREATE USER 'myproject'@'localhost' IDENTIFIED BY 'logmein';
GRANT ALL PRIVILEGES ON myProject.* TO 'myproject'@'localhost';
FLUSH PRIVILEGES;
