import copy as mycopy
import vwb_folder_utils as vfu
import json

UNPUBLISHED_THOUSAND_GENOMES_PARSED_TREE = [{'name': 'Genomics', 'id': 'de5bf30a-78a6-4686-92e6-687b472b1475', 'depth': 1, 'children': [{'name': 'Variant Files', 'id': 'd018eff8-bba1-4d59-b9e0-a7db7ed66422', 'depth': 2, 'children': []}, {'name': 'Aligned Files', 'id': 'f6cc00ad-9d66-4644-8543-7c3ced6bd63f', 'depth': 2, 'children': []}]}, {'name': 'Clinical', 'id': '05f362fe-d205-44a3-b5a8-4ad6d242e8ac', 'depth': 1, 'children': [{'name': 'Synthetic Data', 'id': 'd6e9058e-976f-4f51-9352-43abe59657b7', 'depth': 2, 'children': []}]}]

PUBLISHED_THOUSAND_GENOMES_PARSED_TREE = [{"name" : "Version 1","id" : "13d1ccbc-71d0-46b5-a422-bea85231da7a","properties" : [{"terra-workspace-short-description" : "A brief description.","terra-type" : "data-collection","terra-published-date" : "2023-07-17"}], "depth": 1, "children" : [{'name': 'Genomics', 'id': 'de5bf30a-78a6-4686-92e6-687b472b1475', 'depth': 2, 'children': [{'name': 'Variant Files', 'id': 'd018eff8-bba1-4d59-b9e0-a7db7ed66422', 'depth': 3, 'children': []}, {'name': 'Aligned Files', 'id': 'f6cc00ad-9d66-4644-8543-7c3ced6bd63f', 'depth': 3, 'children': []}]}, {'name': 'Clinical', 'id': '05f362fe-d205-44a3-b5a8-4ad6d242e8ac', 'depth': 2, 'children': [{'name': 'Synthetic Data', 'id': 'd6e9058e-976f-4f51-9352-43abe59657b7', 'depth': 3, 'children': []}]}]}]
       

def increment_tree_depth(tree: []):
    ''' 
    Returns an updated tree in which each node's depth is incremented by 1. 
    Helper method for tests.
    Also useful for constructing widgets that create a folder architecture for a new version based on a previous version.
    '''    
    # Loop through top-level nodes.
    updated_tree = []
    for node in tree:
        updated_node = mycopy.copy(node)
        prev_depth = node['depth']
        updated_node['depth'] = node['depth'] + 1
        # Base case: replace leaf node with incremented depth copy.
        if len(node['children']) == 0:
            updated_tree.append(updated_node)
        else:
            updated_node['children'] = increment_tree_depth(node['children'])
            updated_tree.append(updated_node)
    return updated_tree


class TestClass:
    
    def test_increment_inner_tree_depth(self):
        expected = PUBLISHED_THOUSAND_GENOMES_PARSED_TREE
        actual = [{"name" : "Version 1","id" : "13d1ccbc-71d0-46b5-a422-bea85231da7a","properties" : [{"terra-workspace-short-description" : "A brief description.","terra-type" : "data-collection","terra-published-date" : "2023-07-17"}], "depth": 1, "children" : increment_tree_depth(UNPUBLISHED_THOUSAND_GENOMES_PARSED_TREE)}]
        assert actual == expected

    def test_get_folder_id(self):
        genomics_id = 'de5bf30a-78a6-4686-92e6-687b472b1475'
        variant_files_id = 'd018eff8-bba1-4d59-b9e0-a7db7ed66422'
        aligned_files_id = 'f6cc00ad-9d66-4644-8543-7c3ced6bd63f'
        synthetic_data_id = 'd6e9058e-976f-4f51-9352-43abe59657b7'
        # first in first list -- ├── Name
        assert genomics_id == vfu.get_folder_id('Genomics', PUBLISHED_THOUSAND_GENOMES_PARSED_TREE)
        # not last in not last nested list -- │(   )*├── Name
        assert variant_files_id == vfu.get_folder_id('Variant Files', PUBLISHED_THOUSAND_GENOMES_PARSED_TREE)
        # last in not-last nested list -- │(   )*└── Name
        assert aligned_files_id == vfu.get_folder_id('Aligned Files', PUBLISHED_THOUSAND_GENOMES_PARSED_TREE)
        # last in last nested list -- (   )*└── Name
        assert synthetic_data_id == vfu.get_folder_id('Synthetic Data', PUBLISHED_THOUSAND_GENOMES_PARSED_TREE)
        # no such folder exists
        assert None == vfu.get_folder_id("New Folder", PUBLISHED_THOUSAND_GENOMES_PARSED_TREE)
        
    def test_get_folders_with_depth(self):
        expected = ['Version 1']
        actual = vfu.get_folders_with_depth(1, PUBLISHED_THOUSAND_GENOMES_PARSED_TREE)
        print(actual)
        assert expected == actual
        
        expected = ['Genomics','Clinical']
        actual = vfu.get_folders_with_depth(2, PUBLISHED_THOUSAND_GENOMES_PARSED_TREE)
        print(actual)
        assert expected == actual
        
        expected = ['Variant Files','Aligned Files','Synthetic Data']
        actual = vfu.get_folders_with_depth(3, PUBLISHED_THOUSAND_GENOMES_PARSED_TREE)
        print(actual)
        assert expected == actual
        
        expected = []
        actual = vfu.get_folders_with_depth(4, PUBLISHED_THOUSAND_GENOMES_PARSED_TREE)
        print(actual)
        assert expected == actual
        
    def test_get_published_versions(self):
        expected = ['Version 1']
        actual = vfu.get_published_versions(PUBLISHED_THOUSAND_GENOMES_PARSED_TREE)
        print(actual)
        assert expected == actual
        
        expected = []
        actual = vfu.get_published_versions(UNPUBLISHED_THOUSAND_GENOMES_PARSED_TREE)
        print(actual)
        assert expected == actual
        

        
        