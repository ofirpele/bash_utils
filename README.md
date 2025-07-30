# Bash Utils

**Version:** 1.2.0  
**Author:** Ofir Pele (ofirpele@gmail.com)

## Overview

The most useful parts to me are:
- prompt 
- key bindings
- ls customizations
- grep customizations
- git customizations
- docker customizations (especially for data science projects)


## Installation

To install (will be installed in ~/bash_utils directly from the online repo, not from the local repo):
```bash
source aliases.sh
update_bash_utils
```

If you want to use WinMerge for git (recommended; Beyond Compare Pro Edition is also great, but the free and standard versions do not include 3-way merge) and some other useful git customizations, you should edit dot_gitconfig and then:
```bash 
mv dot_gitconfig ~/.gitconfig
```
