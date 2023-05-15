# Continuous Integration Build Optimization

This repository has been created in order to optimize continuous integration builds. We concentrate on code coverage files that are generated during continuous integration and then deleted without being saved anywhere. For the time being, we are solely focusing on open-source Java Maven projects and GitHub Actions.

# 1. How To Run

Running the scripts are pretty simple, inputs and outputs are created by the scripts and there is no need to format them in between.
There are 3 folders under this project: ``Data Collector``, ``Data`` and ``Job analyzer``. For the testing purposes, we have included only one project named "JSqlParser" in the `data/filtered_repositories.csv` file. You can add more projects to this file and run the scripts for which you would have to follow the steps below. If you wish to only test for the JSqlParser project, you can skip the steps 1.1 and 1.2 and directly go to the section 1.3.

## 1.1 Data Collector

Scripts are run in this order: ``repository_collector``, ``file_collector``, ``content_collector``.

### 1.1.1 repository_collector:

Finds ``["Name", "Link", "Default Branch", "SHA", "Stargazers Count", "Forks Count", "Date"]`` of the repositories and saves it to the ``repositories.csv`` file.

### 1.1.2 file_collector:

Reads repositories.csv file and finds files and their paths related to ``["Maven", "Gradle", "Travis CI", "Github Actions"]``. Then it saves the information to the file ``file_paths.csv``.

### 1.1.3 content_collector:

Reads ``file_paths.csv`` file and finds keywords related to Jacoco, Cobertura or Javadoc. If there is a dependency for these plugins in ``pom.xml`` file or in ``build.gradle`` file it saves the path under its column e.g. ``Maven Jacoco``: ``pom.xml``. If there is a keyword for these dependencies on the yml file like "``jacoco``" it saved the file path under the corresponding CI tool and the plugin name column e.g. ``GA(GitHub Actions) Jacoco``: ``.github/workflows.main.yml``. It also collects if these yml files are potentially using a platform for uploading code coverage results (since our first aim was to find unnecessary code coverage reports) by looking keywords e.g. ``GA Coveralls``: ``.github/workflows/main.yml``.

We used three different script to find information about the repositories because sometimes we encounter errors and this failed the collection of information. Thus, we needed to run the script again however there is an API request limit on GitHub and running the scripts from the beginning (from the collection of repositories) could cause unnecessary request repetition and wasting the requests.

## 1.2 Data

Under this folder there are the files created by the data collector. ``filtered_repositories.csv`` file contains the repositories which you wanted to use for job analyzer. Simply copy the row of the repository from the ``file_contents.csv`` file and paste it here.

## 1.3 Job Analyzer

This script takes the repository information then take the yml file contents and configure it. After configuring, it pushes the changes to the forked repository and automatically triggers GitHub Actions to start the build with configured yml files. In the build, files generated are monitored and analyzed and the results pushed to a specified repository.

The ``main.py`` script contains four parts and is designed to automate the entire procedure.

### 1.3.1 Phases

#### Phase 1: Collection

We fork the repository and add necessary GitHub Environment secrets to the repository (This part done once and not used if there isn't a new repository or change in the added secret). After that we collect the yml file contents. When you run the script for the first time you should set eht environment variable `ADD_SECRETS` to `True` which will add the secrets to the forked repository.

#### Phase 2: Configuring The Yaml Files

In the second phase, we hard coded configuration of files. It adds some steps to yaml files to set up Inotifywait, runs a python script to analyze the Inotifywait logs and lastly pushes the results to another repository.

#### Phase 3: Pushing the Changes

After configuring the files, we push them to our forked version of the corresponding repositories.

#### Phase 4: Analysis

Analysis part are done under by CI builds, using the python script we added to yml file, and the results are pushed to the ci-analyzes repository.

### 1.3.2 Inputs
You can provide your inputs to the `main.py` script by setting the environment variables. The variables are listed below:
<ol>
<li> <b>ADD_SECRETS</b>: If you want to add secrets to the forked repository, set this variable to `True`. You only need to set this variable true once during the very first run.</li>
<li> <b><span style="color: red;">*</span>G_AUTH_OP</b>: Your GitHub personal authentication token</li>
<li> <b><span style="color: red;">*</span>FORKED_OWNER</b>: The GitHub owner who forked the project which is being analyzed</li>
<li> <b><span style="color: red;">*</span>ANALYZER_OWNER</b>: The GitHub username of the owner of the repository specified by variable `CI_ANALYZER_REPO`</li>
<li> <b><span style="color: red;">*</span>CI_ANALYZER_REPO</b>: The name of repository where you want to push the result of the analysis after it is complete</li>
</ol>

### 1.3.3 Run the Script
Before you run the script, make sure you have fulfilled the requirements listed below:
<ol>
<li> You have forked the repository that you want to analysis</li>
<li> You have created a repository where you want to push the results of the analysis</li>
<li> You have created a GitHub personal authentication token</li>
</ol>

Run the script `main.py` specifying all the environment variables. You can use the following command to run the script:
```
ADD_SECRETS=True G_AUTH_OP=<your_github_token> FORKED_OWNER=<forked_owner> ANALYZER_OWNER=<analyzer_owner> CI_ANALYZER_REPO=<ci_analyzer_repo> python main.py
```

For example:
```
ADD_SECRETS=True G_AUTH_OP=ghp_1234567890 FORKED_OWNER=ci-analyzer ANALYZER_OWNER=ci-analyzer CI_ANALYZER_REPO=ci-analyzer-repo python main.py
```

This script will run the experiment in all the projects that are inside the filtered_repositories.csv file.

## 1.4 Log Analysis
First, download the log generated by step running 1.3. By running the job_analyzer/main.py, the OCD tool push the log generated by inotify-wait to a CI analyzer repo specified by the variable `CI_ANALYZER_REPO`. clone the repository in the folder named `ci-analyzes`