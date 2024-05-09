import copy as mycopy
import json
import re
import subprocess
import sys
import tempfile
  
def traverse_tree(name: str, tree: []):
    for item in tree:
        current_name = item['name'].strip()
        if current_name == name:
            return item
        if len(item['children']) != 0:
            tree_child = traverse_tree(name, item['children'])
            if tree_child is not None:
                return tree_child

def get_folder_id(name: str, tree: []):
    """
    Given a JSON representation of the folder tree,
    returns a folder's ID if it exist, else None.
    """
    for item in tree:
        current_name = item['name'].strip()
        if current_name == name:
            return item['id']
        folder_id_from_children = get_folder_id(name, item['children'])
        if folder_id_from_children is not None:
            return folder_id_from_children
    return None

def get_folders_with_depth(depth: int, tree: []):
    """
    Given the workspace ID of a data collection, and a desired depth ( >= 1),
    returns a list of folders in the workspace with that depth.
    """
    folders_at_depth = []
    for item in tree:
        if item['depth'] == depth:
            folders_at_depth.append(item['name'].strip())
        elif item['children']:
            folders_at_depth += get_folders_with_depth(depth, item['children'])
    return folders_at_depth
    
def get_published_versions(tree: []):
    """
    Given a workspace ID, returns the top-level folders for that directory 
    which are published versions of a data collection.
    """
    versions = []
    top_level_folders = get_folders_with_depth(1, tree)
    print(f"top level: {top_level_folders}")
    node = None
    for folder_name in top_level_folders:
        node = traverse_tree(folder_name, tree)
        # If the top-level node has a 'properties' field, we check it for a `terra-published-date`.
        if 'properties' in node:
            properties = node['properties']
            # Although this check seems redundant, it is not. This is necessary because users can set the properties field to the empty string to revert a data collection into its backing workspace via the CLI.
            # This manifests in the JSON output as the properties field still existing but as an empty list of dictionaries.
            if len(properties) !=0:
                properties = properties[0]
            if 'terra-published-date' in properties:
                versions.append(node['name'])
    return versions