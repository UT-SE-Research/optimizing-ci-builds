import utils
import os
import time
import subprocess

def main():
    # GET THE PROJECTS
    os.chdir("..")
    repositories = utils.get_filtered_repos()
    os.chdir("job_analyzer")
    time1 = int(time.time())
    commit=subprocess.check_output(['git', 'rev-parse', '--short', 'HEAD']).decode('ascii').strip()
    for index, repository in enumerate(repositories):
        try:
            # PHASE-1: COLLECTION
            """FORKING THE PROJECT (VIA GITHUB API)"""
            """PARSING THE YAML FILE"""
            """CHANGING THE YAML FILE"""
            forked_owner: str = os.environ["FORKED_OWNER"]
            analyzer_owner: str = os.environ["ANALYZER_OWNER"]
            repo: str = repository["name"].split("/")[1]
            print(f"\nRunning tests on {forked_owner}/{repo}")
            default_branch: str = repository["default_branch"]
            ci_analyzer_repo: str = os.environ["CI_ANALYZER_REPO"]
            add_secrets = os.environ.get('ADD_SECRETS', False)

            try:
                sha: str = utils.retrieve_sha(owner=forked_owner, repo=repo, default_branch=default_branch)
            except ValueError as error:
                print(error)
                pass
            
            if add_secrets:
                try:
                    utils.add_secret(owner=forked_owner, repo=repo)
                except Exception as e:
                    print("exception while adding secret")
                    print(e)
                    pass

            yml_files_path = repository["Github Actions"].split(";")
            yml_files_path = [i for i in yml_files_path if i]

            configured_yaml_files = []
            yaml_shas = []

            for file_path in yml_files_path:
                try:
                    yaml_file, yaml_sha = utils.get_yaml_file(forked_owner, repo, file_path)
                except ValueError as error:
                    print(error)
                    # continue
                    pass
                loaded_yaml = utils.load_yaml(yaml_file)
                job_with_matrix = utils.get_job_with_matrix(loaded_yaml)   
                default_python_version = utils.get_python_version(loaded_yaml)             
                branch_name=str(time1)+'-'+commit
                configured_yaml = utils.configure_yaml_file(yaml_file, repo, file_path, branch_name, job_with_matrix, default_python_version, forked_owner, analyzer_owner,ci_analyzer_repo)
                configured_yaml_files.append(configured_yaml)
                yaml_shas.append(yaml_sha)
            utils.retrieve_sha_ci_analyzes(analyzer_owner, repo, branch_name, ci_analyzer_repo)
            commit_sha = utils.execute(forked_owner, repo, sha, default_branch, yml_files_path, configured_yaml_files, yaml_shas)

        except Exception as e:
            print(e)
            print("There was an error don't ask me what it is.")

if __name__ == "__main__":
    main()
