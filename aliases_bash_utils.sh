function update_bash_utils() 
{
  cd ~ 
  rm bash_utils/ -rf 
  git clone https://github.com/ofirpele/bash_utils.git
  dos2unix bash_utils/* 
  mv -f ~/.bashrc ~/.bashrc_old
  echo source $PWD/bash_utils/bashrc.sh > ~/.bashrc 
  cd -
  bash
}
