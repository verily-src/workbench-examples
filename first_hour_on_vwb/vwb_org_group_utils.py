import json
import subprocess
import sys

def get_org_linked_group_info(org_id, group_name):
    """
    Return an org-linked group's description as JSON.
    """
    wb_command = ["wb","group","describe",f"--org={org_id}",f"--name={group_name}","--format=JSON"]
    result = subprocess.run(wb_command,capture_output=True,text=True)
    group_info = json.loads(result.stdout)
    return group_info


def expiration_duration(org_id, group_name):
    """
    Return the number of days until group role expiration.
    """
    info = get_org_linked_group_info(org_id, group_name)
    return info['expirationDays'] if 'expirationDays' in info else 0


def get_org_linked_group_roles(org_id, group_name):
    """
    Return a flattened mapping of users to roles for a named org-linked group and org ID.
    """
    roles_dict = {role: set() for role in ["ADMIN", "MEMBER", "READER", "SUPPORT"]}
    
    wb_command = ["wb","group","role","list",f"--org={org_id}",f"--name={group_name}","--format=JSON"]
    result = subprocess.run(wb_command,capture_output=True,text=True)
    nested_roles = json.loads(result.stdout)

    for item in nested_roles:
        if item['principal']['principalType'] == "GROUP":
            roles_dict[role].update(get_org_linked_group_roles(item['principal']['groupOrg'], item['principal']['groupName'])["MEMBER"])   
        else:
            for role in item['roles']:
                if item['principal']['userEmail'] != None:
                    roles_dict[role].add(item['principal']['userEmail'])

    return roles_dict

def get_flat_roles_html(roles_dict):
    html = f"""<table style='margin: 0 auto,text-align: left'>"""
    html += "<th>ROLE</th>"
    html += "<th>USER_EMAILS</th>"
    html += "<tr>"
    for role in roles_dict:
        html += "<tr>"
        if roles_dict[role] != set():
            users = ", ".join(str(e) for e in sorted(roles_dict[role]))
            html += f"<td>{role}</td>"
            html += f"<td>{users}</td>"
        else:
            html += f"<td>{role}</td>"
            html += f"<td>NONE</td>"
    html += "</table>"
    return html

if __name__ == "__main__":
    print(get_org_linked_group_info("verily", "emmarogge-friends"))