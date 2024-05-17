import xml.etree.ElementTree as ET

def read_manifest(file_path):
    tree = ET.parse(file_path)
    root = tree.getroot()
    projects = []

    for project in root.findall('project'):
        project_info = {
            'name': project.get('name'),
            'path': project.get('path'),
            'revision': project.get('revision'),
            'upstream': project.get('upstream'),
        }
        projects.append(project_info)

    return projects, tree, root

def modify_remote_and_default(root):
    remote = root.find('remote')
    if remote is not None:
        remote.set('fetch', 'ssh://git@github.com/')
        remote.set('name', 'github')
        remote.set('review', 'github.com')

    default = root.find('default')
    if default is not None:
        default.set('remote', 'github')
        default.set('revision', 'refs/heads/master')

def modify_projects(projects):
    for project in projects:
        # Add prefix to the name and replace '/' with '.'
        project['name'] = project['name'].replace('/', '.')
        # Change the revision to the new specified value
        project['revision'] = project['upstream'].replace('refs/heads/', '')

def update_tree(tree, root, projects):
    for project in root.findall('project'):
        for proj in projects:
            if project.get('name') == proj['name'].replace('sdx.le.', '').replace('.', '/'):
                project.set('path', proj['path'])
                project.set('revision', proj['revision'])
                project.set('upstream', proj['upstream'])
                project.set('name', 'khoacavli/sdx35.le.' + proj['name'])
    
    return tree

def write_manifest(tree, output_file):
    tree.write(output_file, encoding='UTF-8', xml_declaration=True)

# Example usage:
# Read the manifest
file_path = '.repo/manifest.xml'
projects, tree, root = read_manifest(file_path)

# Modify remote and default elements
modify_remote_and_default(root)

# Modify project names and revisions
modify_projects(projects)

# Update the XML tree with the modified project information
tree = update_tree(tree, root, projects)

# Write the modified tree to a new manifest file
output_file = 'modified_manifest.xml'
write_manifest(tree, output_file)
