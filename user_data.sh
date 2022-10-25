#! /bin/bash
sudo yum -y update
sudo yum install git -y
sudo yum install python3 -y
sudo yum install python3-pip
sudo git clone https://github.com/jeba1/Flaskapp.git
cd Flaskapp
pip3 install -r requirements.txt
mkdir -p ~/app/src
cp app.py requirements.txt test_candidates.py ~/app/src
export TC_DYNAMO_TABLE=Candidates
sudo cp gunicorn /etc/systemd/system/gunicorn.service
sudo systemctl daemon-reload

sudo systemctl start gunicorn

sudo systemctl enable gunicorn

