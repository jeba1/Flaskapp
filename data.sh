#!/bin/bash
yum -y update
sudo yum install git -y
sudo yum install python3 -y
sudo yum install python3-pip
git clone https://github.com/jeba1/Flaskapp.git
cd Flaskapp
pip3 install -r requirements.txt
cp app.py requirements.txt test_candidates.py /home/ssm-user/app/src
sudo cp gunicon /etc/systemd/system/gunicorn.service
sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn

