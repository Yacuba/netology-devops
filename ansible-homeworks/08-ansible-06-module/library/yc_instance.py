#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2026, Yacuba
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

DOCUMENTATION = r'''
---
module: yc_instance

short_description: Manage Yandex Cloud compute instances via yc CLI

version_added: "1.1.0"

description:
    - Creates, verifies, or deletes virtual machine instances in Yandex Cloud using yc CLI.
    - Ensures full idempotency by verifying existing instances before executing modifications.
    - Supports check mode.

options:
    name:
        description:
            - Name of the virtual machine instance.
        required: true
        type: str
    zone:
        description:
            - Availability zone.
        required: false
        default: "ru-central1-a"
        type: str
    subnet_name:
        description:
            - Subnet name where the instance interface will be attached.
        required: false
        default: "default-ru-central1-a"
        type: str
    cores:
        description:
            - Number of vCPU cores.
        required: false
        default: 2
        type: int
    memory:
        description:
            - RAM size in gigabytes.
        required: false
        default: 2
        type: int
    core_fraction:
        description:
            - Guaranteed vCPU performance percentage (e.g., 20, 50, 100).
        required: false
        default: 20
        type: int
    image_family:
        description:
            - OS image family from standard-images catalog.
        required: false
        default: "almalinux-9"
        type: str
    disk_size:
        description:
            - Boot disk size in gigabytes.
        required: false
        default: 15
        type: int
    ssh_key_path:
        description:
            - Path to public SSH key file.
        required: false
        default: "~/.ssh/id_ed25519.pub"
        type: str
    state:
        description:
            - Target state of the compute instance.
        required: false
        default: "present"
        choices: ["present", "absent"]
        type: str

author:
    - Yacuba (@Yacuba)
'''

EXAMPLES = r'''
- name: Create a virtual machine instance in Yandex Cloud
  yc_instance:
    name: test-vm
    zone: ru-central1-a
    subnet_name: default-ru-central1-a
    cores: 2
    memory: 2
    core_fraction: 20
    image_family: almalinux-9
    disk_size: 15
    ssh_key_path: ~/.ssh/id_ed25519.pub
    state: present

- name: Terminate instance
  yc_instance:
    name: test-vm
    state: absent
'''

RETURN = r'''
instance:
    description: Details of the provisioned or existing virtual machine.
    type: dict
    returned: when state is present
    sample:
        id: "fhm123456789abcdef"
        name: "test-vm"
        status: "RUNNING"
        external_ip: "158.160.10.20"
        internal_ip: "10.128.0.15"
message:
    description: Status summary of performed operation.
    type: str
    returned: always
    sample: "Instance test-vm already exists and is up-to-date."
'''

import json
import os
from ansible.module_utils.basic import AnsibleModule


def extract_ips(instance_data):
    internal_ip = None
    external_ip = None
    network_interfaces = instance_data.get('network_interfaces', [])
    if network_interfaces:
        primary_iface = network_interfaces[0]
        internal_ip = primary_iface.get('primary_v4_address', {}).get('address')
        external_ip = primary_iface.get('primary_v4_address', {}).get('one_to_one_nat', {}).get('address')

    return internal_ip, external_ip


def get_instance_info(module, name):
    rc, stdout, stderr = module.run_command(
        ['yc', 'compute', 'instance', 'get', '--name', name, '--format', 'json'],
        check_rc=False
    )
    if rc == 0:
        try:
            return json.loads(stdout)
        except Exception as e:
            module.fail_json(msg=f"Failed to parse yc output for {name}: {str(e)}")
    return None


def run_module():
    module_args = dict(
        name=dict(type='str', required=True),
        zone=dict(type='str', required=False, default='ru-central1-a'),
        subnet_name=dict(type='str', required=False, default='default-ru-central1-a'),
        cores=dict(type='int', required=False, default=2),
        memory=dict(type='int', required=False, default=2),
        core_fraction=dict(type='int', required=False, default=20),
        image_family=dict(type='str', required=False, default='almalinux-9'),
        disk_size=dict(type='int', required=False, default=15),
        ssh_key_path=dict(type='str', required=False, default='~/.ssh/id_ed25519.pub'),
        state=dict(type='str', required=False, default='present', choices=['present', 'absent'])
    )

    result = dict(
        changed=False,
        instance=None,
        message=''
    )

    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )

    # Verify that yc CLI binary is available
    if module.get_bin_path('yc') is None:
        module.fail_json(msg="Yandex Cloud CLI 'yc' is not installed or not found in PATH.")

    name = module.params['name']
    state = module.params['state']
    existing_instance = get_instance_info(module, name)

    if state == 'present':
        if existing_instance:
            internal_ip, external_ip = extract_ips(existing_instance)
            result['changed'] = False
            result['instance'] = {
                'id': existing_instance.get('id'),
                'name': existing_instance.get('name'),
                'status': existing_instance.get('status'),
                'internal_ip': internal_ip,
                'external_ip': external_ip
            }
            result['message'] = f"Instance {name} already exists."
            module.exit_json(**result)

        # Instance does not exist and needs to be created
        result['changed'] = True
        result['message'] = f"Instance {name} will be created."

        if module.check_mode:
            module.exit_json(**result)

        ssh_key_path = os.path.expanduser(module.params['ssh_key_path'])
        if not os.path.isfile(ssh_key_path):
            module.fail_json(msg=f"Public SSH key file not found: {ssh_key_path}")

        create_cmd = [
            'yc', 'compute', 'instance', 'create',
            '--name', name,
            '--zone', module.params['zone'],
            '--network-interface', f"subnet-name={module.params['subnet_name']},nat-ip-version=ipv4",
            '--create-boot-disk', f"image-family={module.params['image_family']},image-folder-id=standard-images,size={module.params['disk_size']}",
            '--cores', str(module.params['cores']),
            '--memory', str(module.params['memory']),
            '--core-fraction', str(module.params['core_fraction']),
            '--ssh-key', ssh_key_path,
            '--format', 'json'
        ]

        rc, stdout, stderr = module.run_command(create_cmd)
        if rc != 0:
            module.fail_json(msg=f"Failed to create instance {name}: {stderr}", **result)

        try:
            created_data = json.loads(stdout)
            internal_ip, external_ip = extract_ips(created_data)
            result['instance'] = {
                'id': created_data.get('id'),
                'name': created_data.get('name'),
                'status': created_data.get('status'),
                'internal_ip': internal_ip,
                'external_ip': external_ip
            }
            result['message'] = f"Instance {name} created successfully."
        except Exception:
            # Fallback if creation output doesn't contain complete network info immediately
            fresh_info = get_instance_info(module, name)
            if fresh_info:
                internal_ip, external_ip = extract_ips(fresh_info)
                result['instance'] = {
                    'id': fresh_info.get('id'),
                    'name': fresh_info.get('name'),
                    'status': fresh_info.get('status'),
                    'internal_ip': internal_ip,
                    'external_ip': external_ip
                }

        module.exit_json(**result)

    elif state == 'absent':
        if not existing_instance:
            result['changed'] = False
            result['message'] = f"Instance {name} does not exist. Nothing to delete."
            module.exit_json(**result)

        result['changed'] = True
        result['message'] = f"Instance {name} will be deleted."

        if module.check_mode:
            module.exit_json(**result)

        delete_cmd = ['yc', 'compute', 'instance', 'delete', '--name', name]
        rc, stdout, stderr = module.run_command(delete_cmd)
        if rc != 0:
            module.fail_json(msg=f"Failed to delete instance {name}: {stderr}", **result)

        result['message'] = f"Instance {name} deleted successfully."
        module.exit_json(**result)


def main():
    run_module()


if __name__ == '__main__':
    main()