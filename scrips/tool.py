import os
import subprocess
import xml.etree.ElementTree as ET

def repo_exists(name, debug=False):
    # Check if the repo exists
    cmd = ["gh", "repo", "view", name]
    if debug:
        print(" ".join(cmd))
        return False  # Simulate that the repo doesn't exist in debug mode
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return result.returncode == 0

def delete_repo(name, debug=False):
    # Delete the repo if it exists
    cmd = ["gh", "repo", "delete", name, "--confirm"]
    if debug:
        print(" ".join(cmd))
    else:
        subprocess.run(cmd, check=True)

def remote_exists(remote_name, debug=False):
    # Check if the remote exists in the local repository
    cmd = ["git", "remote"]
    if debug:
        print(" ".join(cmd))
        return False  # Simulate that the remote doesn't exist in debug mode
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    remotes = result.stdout.decode().split()
    return remote_name in remotes

def remove_local_remote(remote_name, debug=False):
    # Remove the remote in the local repository if it exists
    if remote_exists(remote_name, debug):
        cmd = ["git", "remote", "remove", remote_name]
        if debug:
            print(" ".join(cmd))
        else:
            subprocess.run(cmd, check=True)

def process_project_info(name, path, revision, upstream, remote):
    # Replace / with . in the name
    processed_name = name.replace('/', '.')
    # Add prefix sdx35/le/ to the name
    processed_name = f"sdx35.le.{processed_name}"
    # Return processed information
    return {
        'name': processed_name,
        'path': path,
        'revision': revision,
        'upstream': upstream,
        'remote': remote,
        "tag_name": "OWRT.PRODUCT.2.1.r1-12100-SDX35.0"
    }

def branch_exists(branch_name, debug=False):
    # Check if the branch exists in the local repository
    cmd = ["git", "branch", "--list", branch_name]
    if debug:
        print(" ".join(cmd))
        return False  # Simulate that the branch doesn't exist in debug mode
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    branches = result.stdout.decode().split()
    return branch_name in branches

def tag_exists(tag_name, debug=False):
    # Check if the tag exists in the local repository
    cmd = ["git", "tag", "--list", tag_name]
    if debug:
        print(" ".join(cmd))
        return False  # Simulate that the tag doesn't exist in debug mode
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    tags = result.stdout.decode().split()
    return tag_name in tags

def remove_tag(tag_name, debug=False):
    # Remove the tag if it exists
    if tag_exists(tag_name, debug):
        cmd = ["git", "tag", "-d", tag_name]
        if debug:
            print(" ".join(cmd))
        else:
            subprocess.run(cmd, check=True)

def create_and_push_tag(tag_name, remote, debug=False):
    # Remove existing tag if it exists
    remove_tag(tag_name, debug)

    # Create a tag for the current branch
    if debug:
        print(f"git tag {tag_name}")
    else:
        subprocess.run(["git", "tag", tag_name], check=True)
    
    # Push the tag to the remote repository
    if debug:
        print(f"git push")
    else:
        subprocess.run(["git", "push", remote, tag_name], check=True)

def process_and_push_repo(name, path, revision, upstream, remote, tag_name, reset=True, debug=False):
    # Store the current working directory
    initial_dir = os.getcwd()
    remote="cavli"

    # Step 1: Change directory to path
    if debug:
        print(f"cd {path}")
    else:
        os.chdir(path)

    # Check if repo exists and delete it if necessary
    if repo_exists(name, debug):
        if reset:
            delete_repo(name, debug)
        else:
            os.chdir(initial_dir)
            return
    # Remove the remote if it exists
    remove_local_remote(remote, debug)

    # Step 2: Create new repo with name
    if debug:
        print(f"gh repo create {name} --private --source=. --remote={remote}")
    else:
        subprocess.run(["gh", "repo", "create", name, "--private", "--source=.", f"--remote={remote}"], check=True)

    # Step 3: Checkout to upstream (remove refs/heads/)
    branch_name = upstream.replace("refs/heads/", "")
    try:
        if debug:
            print(f"git checkout -b {branch_name}")
        else:
            subprocess.run(["git", "checkout", "-b", branch_name], check=True)
    except subprocess.CalledProcessError:
        print("Failed to checkout branch. Ignoring.")

    # Step 4: Push the branch to remote
    if debug:
        print(f"git push --set-upstream {remote} {branch_name}")
    else:
        subprocess.run(["git", "push", "--set-upstream", remote, branch_name], check=True)

    # Step 5: Create and push the tag
    create_and_push_tag(tag_name, remote, debug)

    # Change back to the initial directory
    if debug:
        print(f"cd {initial_dir}")
    else:
        os.chdir(initial_dir)


def parse_manifest(file_path):
    try:
        tree = ET.parse(file_path)
        root = tree.getroot()

        # Extract default remote information
        default_remote = root.find('default').get('remote')

        projects = []

        for project in root.findall('project'):
            project_info = {
                'name': project.get('name'),
                'path': project.get('path'),
                'revision': project.get('upstream').replace("refs/heads/", ""),
                'upstream': project.get('upstream'),
                'remote': project.get('remote', default_remote)  # Use default remote if not specified
            }
            processed_info_processed = process_project_info(**project_info)
            projects.append(processed_info_processed)

        return projects
    except ET.ParseError as e:
        print(f"Error parsing XML: {e}")
        return None

def main():
    manifest_file = '.repo/manifest.xml'
    projects = parse_manifest(manifest_file)

    if projects is not None:
        print("Collected project information:")
        for project in projects:
            process_and_push_repo(**project)
    else:
        print("Failed to parse the manifest file.")

if __name__ == "__main__":
    main()
