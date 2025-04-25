install:
	cd ansible; ansible-playbook -i inventory.yml playbook.yml --ask-become-pass

reinstall:
	cd ansible; ansible-playbook -i inventory.yml playbook.yml --ask-become-pass --extra-vars "reinstall=true"

inventory:
	cd ansible; ansible-inventory -i inventory.yml --graph

provision:
	cd terraform; terraform apply

hide:
	git secret hide -m -P

reveal:
	git secret reveal -f -P
