import requests
import smtplib
import os
import paramiko
import boto3
import time
import schedule

EMAIL_ADDRESS = os.environ.get('EMAIL_ADDRESS')
EMAIL_PASSWORD = os.environ.get('EMAIL_PASSWORD')
SERVER_URL = os.environ.get('SERVER_URL')
EC2_PUBLIC_IP = os.environ.get('EC2_PUBLIC_IP')

ec2_client = boto3.client("ec2", region_name="eu-west-1")
ec2_resource = boto3.resource("ec2", region_name="eu-west-1")

ec2_instance_id = "i-07c11be7a232edv2w"


def restart_server_and_container():
    # restart EC2 server
    print('Rebooting the server...')
    response = ec2_client.reboot_instances(
        InstanceIds=[
            ec2_instance_id,
        ],
        DryRun=False # if True, checks if you have permissions, without making the request
    )
    print(response)

    # restart the application
    while True:
        nginx_server = ec2_resource.Instance(ec2_instance_id)
        if nginx_server.state["Name"] == 'running':
            time.sleep(5)
            restart_container()
            break


def send_notification(email_msg):
    print('Sending an email...')
    with smtplib.SMTP('smtp.gmail.com', 587) as smtp:
        smtp.starttls()
        smtp.ehlo()
        smtp.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
        message = f"Subject: NGINX SERVER IS DOWN\n{email_msg}"
        smtp.sendmail(EMAIL_ADDRESS, EMAIL_ADDRESS, message)

# if the app returns 5xx status codes
def restart_container():
    print('Restarting the application...')
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(hostname=EC2_PUBLIC_IP, username='ec2-user', key_filename='~/.ssh/id_rsa')
    stdin, stdout, stderr = ssh.exec_command('docker start nginx-server')
    print(stdout.readlines())
    ssh.close()


def monitor_application():
    try:
        # if the container is down we won't even reach the server
        response = requests.get(SERVER_URL)
        if response.status_code == 200:
            print('Application is running successfully!')
        else:
            print('Application Down. Fix it!')
            msg = f'Application returned {response.status_code}'
            send_notification(msg)
            restart_container()
    except Exception as ex:
        print(f'Connection error happened: {ex}')
        msg = 'Application not accessible at all'
        send_notification(msg)
        restart_server_and_container()


schedule.every(5).minutes.do(monitor_application)

while True:
    schedule.run_pending()