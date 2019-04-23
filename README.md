```
         ________         _____    ___
        / ____/ /_  ___  / __/ |  / (_)___
       / /   / __ \/ _ \/ /_ | | / / /_  /
      / /___/ / / /  __/ __/ | |/ / / / /_
      \____/_/ /_/\___/_/    |___/_/ /___/
```

# A simple tool for generating call graphs for Chef roles

## Description
Reasoning about exactly which Chef recipes will run when a particular Chef
role is invoked can be challenging. Refactoring roles can be complex, and
extracting long lists of recipes by hand is tedious and error-prone.

ChefViz helps to alleviate this pain by providing a lightweight interface for
generating visual representation of Chef roles. For example:

![Sample Graph Image](/sample_images/simple.png)


The nodes represent the Chef recipes.
The labelled edges indicate the order in which the recipes will be called.
Please note that this is a call graph, not a dependency graph!

## Modes
ChefViz has two modes: `setup` and `graph`. The `setup` mode is used to configure the tool for use
with your desired repos. The `graph` mode is used to generate
graphs.
```
$ ./chefviz
Usage: chefviz <command> [command-options] [command-parameters]

Tool for generating call graphs for chef roles.
For help using a specific command, try the following:

    ./chefviz <command> -h

COMMANDS

    setup       Configure a new chef repository for use with ChefViz
    graph       Generate a call graph for a specified chef role  
```


## Setup
Before using ChefViz for the first time, you must configure paths to your target chef role
by running `chefviz setup`:
```
$ ./chefviz setup -h
Usage: chefviz setup <parameters>
Description: Configure a chef repo for use with the ChefViz tool.
Options:
    -n, --repo-name [REPO_NAME]      Name to assign to this repo
    -r, --roles [ROLES_PATH]         Path to "roles" directory in target repo (default: <REPO_PATH>/roles)
    -c, --cookbooks [COOKBOOKS_PATH] Path to "cookbooks" directory in target repo (default: <REPO_PATH>/cookbooks)
	    
```
If you do not specify paths to the roles and cookbooks directories for your Chef repo, the standard 
directory locations will be used by default.

Example:
```
$ ./chefviz setup -n prod -r ~/projects/prod_chef/chef/roles -c ~/projects/prod_chef/chef/cookbooks
Configuration was updated for prod!
```

Running `chefviz setup` writes all required parameters to a json-formatted file called `.config`, located
at the root of the ChefViz app. If you wish, you may edit this file manually.


## Graphing
To generate a graph, specify the name of the configuration you wish to use, and the name of the role to be graphed.
```
$ ./chefviz graph -h
Usage: chefviz graph <name ><role> [options]
Description: Generate a call graph for the specified chef role.
    -n, --name [NAME]                Chef config to use
    -r, --role [ROLE]                Chef role
    -c, --conifg-file [CONFIG]       Configuration file (default: ChefViz config file)
    -o, --output-filename [FILENAME] Name for output file (default: <role>.pdf)
    -h, --help                       Show this message
```
Note that ChefViz will use it's internal `.config` configuration file by default, but the user
has the ability to specify their own config file if they so wish (for example, for one-off tests).

Example: generating a graph for the role 'test1' for a repo called 'test', which has previously been
configured using `chefviz setup`:
```
$ ./chefviz graph -n test -r test1 -o ~/myimages/test1_graph.pdf
Graph was generated for test1!
```





