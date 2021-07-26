set -x SSH_ENV $HOME/.cache/ssh_environment

function ssh_test_agent
	ssh-add -l &> /dev/null
	if [ $status = 2 ]
		return 1
	else
		return 0
	end
end

function ssh_connect_agent
	mkdir -p $HOME/.cache
	touch $HOME/.cache/ssh_environment
	. $SSH_ENV > /dev/null
	ssh_test_agent
end

function ssh_start_agent
	if not ssh_connect_agent
		ssh-agent -c | sed 's/^echo/#echo/' > $SSH_ENV
      	chmod 600 $SSH_ENV 
      	. $SSH_ENV > /dev/null
	end
end

function ssh_stop_agent
	if not ssh_connect_agent
		return 1
	else
		kill $SSH_AGENT_PID
	end
end
