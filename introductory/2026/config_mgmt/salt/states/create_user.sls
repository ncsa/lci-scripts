workshop_user:
  user.present:
    - name: workshop_salt
    - uid: 3001
    - fullname: Salt Workshop User

workshop_ssh_dir:
  file.directory:
    - name: /home/workshop_salt/.ssh
    - user: workshop_salt
    - group: workshop_salt
    - mode: 700
    - require:
      - user: workshop_user
