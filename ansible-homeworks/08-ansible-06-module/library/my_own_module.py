#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2026, Yacuba
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

DOCUMENTATION = r'''
---
module: my_own_module

short_description: Creates or updates a file with specified content

version_added: "1.0.0"

description:
    - Checks whether a file exists at the specified path.
    - If the file does not exist or its content differs from the target content, writes the file.
    - Ensures full idempotency by avoiding modifications when content matches.

options:
    path:
        description:
            - Absolute or relative path to the target file.
        required: true
        type: str
    content:
        description:
            - Text content to be written to the file.
        required: true
        type: str

author:
    - Yacuba (@Yacuba)
'''

EXAMPLES = r'''
- name: Create a file with desired content
  my_own_module:
    path: /tmp/test_file.txt
    content: "Hello from my own module!"
'''

RETURN = r'''
original_message:
    description: Content that was provided to be written or verified.
    type: str
    returned: always
    sample: 'Hello world'
message:
    description: Status message describing what action was performed.
    type: str
    returned: always
    sample: 'File /tmp/test_file.txt successfully updated.'
'''

import os
from ansible.module_utils.basic import AnsibleModule


def run_module():
    module_args = dict(
        path=dict(type='str', required=True),
        content=dict(type='str', required=True)
    )

    result = dict(
        changed=False,
        original_message='',
        message=''
    )

    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )

    path = os.path.expanduser(module.params['path'])
    content = module.params['content']
    result['original_message'] = content

    file_exists = os.path.exists(path)
    current_content = None

    if file_exists:
        try:
            with open(path, 'r', encoding='utf-8') as f:
                current_content = f.read()
        except Exception as e:
            module.fail_json(msg=f"Failed to read file {path}: {str(e)}", **result)

    # Determine whether changes are needed
    if not file_exists:
        result['changed'] = True
        result['message'] = f"File {path} does not exist and will be created."
    elif current_content != content:
        result['changed'] = True
        result['message'] = f"Content of {path} differs and will be updated."
    else:
        result['changed'] = False
        result['message'] = f"File {path} is already up-to-date. No changes made."

    # Return predicted result if check mode is enabled
    if module.check_mode:
        module.exit_json(**result)

    # Perform write operation if changes are required
    if result['changed']:
        try:
            dirname = os.path.dirname(path)
            if dirname and not os.path.exists(dirname):
                os.makedirs(dirname, exist_ok=True)

            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            result['message'] = f"File {path} successfully written."
        except Exception as e:
            module.fail_json(msg=f"Failed to write file {path}: {str(e)}", **result)

    module.exit_json(**result)


def main():
    run_module()


if __name__ == '__main__':
    main()