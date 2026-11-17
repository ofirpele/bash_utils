function op_docker_run_common_flags() 
{
	local ret="\
		-e RUNS_ON_DOCKER=true \
		--rm \
		--privileged=true \
		-v $PWD/../output/:/output/ \
		-v $PWD/../data/:/data/ \
		-v $PWD/../config/:/config/ \
		-v /:/top/ \
		--net=host \
		"
	echo "$ret"
}

function docker_out() 
{
    echo "=============================================="
    cat output/stdout_stderr_local_filenames.txt
    echo "=============================================="
    cat output/stdout_stderr_local_filenames.txt | xargs cat
    echo "=============================================="
}

# usage: 
# docker_run params_to_script
# The image name is the basename of current pwd converted to lowercase
function docker_run() 
{
	docker_run_name	$(basename_pwd_lower_case) $@
}

# usage:
# see docker_run
function docker_run_foreground() 
{
	docker_run_foreground_name $(basename_pwd_lower_case) $@
}

# usage:
# docker_run_name image_name params_to_script
function docker_run_name() 
{
  rm -f output/stdout_stderr_local_filenames.txt
	sudo docker run -d -e REDIRECT_OUTPUT=true $(op_docker_run_common_flags) $@
	sleep 3
	echo
    if test -f output/stdout_stderr_local_filenames.txt; then
        docker_out
    else
        echo "output was not created"
        echo "Check that you have ofirpele_utils.py and default_imports.py"
        echo "Check that the first line of your python run script is from default_imports import *"
        echo "Running docker_run_foreground_name $@"
        echo
        docker_run_foreground_name $@
    fi
}

# usage:
# see docker_run_name
function docker_run_foreground_name() 
{
	sudo docker run $(op_docker_run_common_flags) $@
}

# usage: docker_build
# The image name is the basename of current pwd converted to lowercase
function docker_build() 
{
	sudo docker build -t $(basename_pwd_lower_case) . 
}

# usage: docker_build_run
# The image name is the basename of current pwd converted to lowercase
function docker_build_run() 
{
	docker_build
	echo
	docker_run $@
}

# usage: docker_build image_name
function docker_build_name() 
{
	sudo docker build -t $@ . 
}

function docker_ps() 
{
	sudo docker ps
}

function docker_kill() 
{
	sudo docker container kill "$@"
}

function docker_killall() 
{		 
	sudo docker container kill $(sudo docker ps -q)
}

function docker_stop() 
{
	sudo docker container stop "$@"
}

function docker_stop_all() 
{
	sudo docker container stop $(sudo docker ps -q)
}

function docker_clean() 
{
	sudo docker container rm $(sudo docker container ls -aq)
	sudo docker image prune
}

function docker_image_ls() 
{
	sudo docker images
}

function docker_image_rm() 
{
	sudo docker image rm "$@"
}

function docker_killall_cleanall() 
{
	sudo docker container stop $(sudo docker ps -q)
	sudo docker container rm $(sudo docker container ls -aq)
	sudo docker image rm $(sudo docker images -aq)
}
