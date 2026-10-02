---
- name: Update apt cache
  apt:
    update_cache: yes
    cache_valid_time: 3600

- name: Install basic utilities and postgres client tools
  apt:
    name:
      - curl
      - git
      - postgresql-client
      - python3-psycopg2
    state: present

- name: Set timezone to Europe/Paris
  timezone:
    name: Europe/Paris

- name: Harden SSH configuration
  lineinfile:
    path: /etc/ssh/sshd_config
    regexp: "{{ item.regexp }}"
    line: "{{ item.line }}"
    validate: 'sshd -t -f %s'
  loop:
    - { regexp: '^#?PermitRootLogin', line: 'PermitRootLogin no' }
    - { regexp: '^#?PasswordAuthentication', line: 'PasswordAuthentication no' }
  notify: Restart sshd
