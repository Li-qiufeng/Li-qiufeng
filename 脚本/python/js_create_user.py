#!/usr/bin/env python
import requests
import json, sys 
from pprint import pprint

# jumpserver创建用户脚本
token = "8c59989026b3b2a54f405a144e6f37a3663573cc"
url = 'https://xxx/api/assets/v1/system-user/'

def get_user_info(user, env, auth_file):

    header_info = { "Authorization": 'Token ' + token }
    
    user_body_info = { 
        "name": env + '_' + user,
        "username": user,
        "comment": env + '_' + user,
        "protocol": "ssh",
        "shell": "/bin/bash",
        "login_mode": "auto"
    }   

    payload = { 
        "search": "username",
        "order": "name"
    }   

    # create user
    user_response = requests.post(url, headers=header_info, data=user_body_info)
    # pprint(json.loads(user_response.text))

    # find user id
    id_response = requests.get(url, headers=header_info, data=payload)
    for list in json.loads(id_response.text):
        for k, v in list.items():
            if k == "username" and v == user:
                #print list['id']
                user_id = list['id']

    # buile the body
    file_auth_body_info = { 
        "name": env + '_' + user,
        "username": user,
        "private_key": open(auth_file, 'r').read(),
        "id": user_id
    }   
    file_auth_url = url + user_id + '/auth-info/'
    file_auth_response = requests.put(file_auth_url, headers=header_info, data=file_auth_body_info)
    print file_auth_response

if __name__ == '__main__':
      user=str(sys.argv[1])
      env=str(sys.argv[2])
      auth_file=str(sys.argv[3])
      Status = get_user_info(user, env, auth_file)

