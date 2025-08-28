import yaml
import sys
import os
from collections import defaultdict

def find_refs(data):
    """Recursively finds all '$ref' values in the data."""
    refs = set()
    if isinstance(data, dict):
        for k, v in data.items():
            if k == '$ref' and isinstance(v, str):
                refs.add(v)
            else:
                refs.update(find_refs(v))
    elif isinstance(data, list):
        for item in data:
            refs.update(find_refs(item))
    return refs

def generate_dot_file(output_filename, source_nodes, endpoint_label, target_groups, all_edges, dark_mode=False):
    """
    Generates a DOT graph file combining multiple target types with a dark mode option.
    """
    # --- Define color palettes ---
    if dark_mode:
        palette = {
            "bgcolor": "#2d333b",
            "fontcolor": "#cdd9e5",
            "cluster_color": "#cdd9e5",
            "default_edge": "#768390", # Renamed for 
            "endpoints": "#37516b",
            "schemas": "#345a3f",
            "responses": "#634c23",
            "security": "#6b3940",
            "schemas_edge": "#53b668",
            "responses_edge": "#d8a436",
            "security_edge": "#e26a77"
        }
    else:
        palette = {
            "bgcolor": "#FFFFFF",
            "fontcolor": "#000000",
            "cluster_color": "#000000",
            "default_edge": "#000000", # Renamed for clarity
            "endpoints": "#e6f2ff",
            "schemas": "#d4edda",
            "responses": "#fff3cd",
            "security": "#f8d7da",
            "schemas_edge": "#28a745",
            "responses_edge": "#ffc107",
            "security_edge": "#dc3545"
        }

    with open(output_filename, 'w') as f:
        f.write('digraph OpenAPI_Dependencies {\n')
        f.write(f'  bgcolor="{palette["bgcolor"]}";\n')
        f.write(f'  fontcolor="{palette["fontcolor"]}";\n')
        f.write('  rankdir="TB";\n')
        f.write('  splines="curved";\n')
        f.write('  compound=true;\n')
        f.write('  concentrate=true;\n')
        f.write('  graph [nodesep=0.5, ranksep=2.5];\n')
        f.write(f'  node [shape=box, style="rounded,filled", fontcolor="{palette["fontcolor"]}"];\n')
        # MODIFIED: Removed the global edge color setting. It will now be set per-edge.
        
        # Endpoints Subgraph
        f.write('  subgraph cluster_endpoints {\n')
        f.write(f'    label = "{endpoint_label}";\n')
        f.write(f'    fontcolor = "{palette["cluster_color"]}";\n')
        f.write(f'    color = "{palette["cluster_color"]}";\n')
        f.write('    margin = 25;\n')
        f.write(f'    node [fillcolor="{palette["endpoints"]}"];\n')
        for node in sorted(list(source_nodes)):
            f.write(f'    "{node}";\n')
        f.write('  }\n\n')

        # Target Subgraphs
        for target_label, target_nodes in target_groups.items():
            if target_nodes:
                f.write(f'  subgraph cluster_{target_label.lower()} {{\n')
                f.write(f'    label = "{target_label}";\n')
                f.write(f'    fontcolor = "{palette["cluster_color"]}";\n')
                f.write(f'    color = "{palette["cluster_color"]}";\n')
                f.write('    margin = 25;\n')
                f.write(f'    node [fillcolor="{palette.get(target_label.lower(), "#ffffff")}"];\n')
                for node in sorted(list(target_nodes)):
                    f.write(f'    "{node}";\n')
                f.write('  }\n\n')

        # --- MODIFIED: Logic to color edges based on their target type ---
        # Create a reverse mapping from a node name to its type (e.g., "User" -> "schemas")
        node_to_type = {}
        for target_label, target_nodes in target_groups.items():
            for node in target_nodes:
                node_to_type[node] = target_label.lower()

        f.write('  // Edges (Dependencies)\n')
        for source, target in sorted(list(all_edges)):
            target_type = node_to_type.get(target, "")
            edge_color = palette.get(f"{target_type}_edge", palette["default_edge"])
            f.write(f'  "{source}" -> "{target}" [color="{edge_color}"];\n')
        
        f.write('}\n')
    print(f"Successfully generated DOT file at '{output_filename}'")

def main(spec_file, dark_mode=False):
    """Main function to parse the spec and generate graphs."""
    try:
        with open(spec_file, 'r') as f:
            spec = yaml.safe_load(f)
    except FileNotFoundError:
        print(f"Error: The file '{spec_file}' was not found.")
        sys.exit(1)
    except yaml.YAMLError as e:
        print(f"Error parsing YAML file: {e}")
        sys.exit(1)

    if 'paths' not in spec:
        print("No 'paths' found in the specification. Exiting.")
        return

    script_dir = os.path.dirname(os.path.realpath(__file__))
    project_root = os.path.dirname(script_dir)
    output_dir = os.path.join(project_root, 'visuals')
    
    os.makedirs(output_dir, exist_ok=True)
    print(f"Output directory '{output_dir}' is ready.")

    valid_http_methods = {'get', 'put', 'post', 'delete', 'options', 'head', 'patch', 'trace'}

    paths_by_tag = defaultdict(dict)
    for path, path_item in spec.get('paths', {}).items():
        for method in set(path_item.keys()) & valid_http_methods:
            operation = path_item[method]
            if not isinstance(operation, dict):
                continue

            tags = operation.get('tags', ['untagged'])
            for tag in tags:
                if path not in paths_by_tag[tag]:
                    paths_by_tag[tag][path] = {}
                paths_by_tag[tag][path][method] = operation

    for tag, paths in paths_by_tag.items():
        print(f"\n--- Processing tag: {tag} ---")
        
        source_nodes = set()
        edges_to_schemas = set()
        edges_to_responses = set()
        edges_to_security = set()

        for path, path_item in paths.items():
            for method, operation in path_item.items():
                path_node_name = f"{method.upper()} {path}"
                source_nodes.add(path_node_name)
            
                if 'security' in operation and operation['security'] is not None:
                    for security_req in operation['security']:
                        for scheme_name in security_req.keys():
                            edges_to_security.add((path_node_name, scheme_name))

                all_refs = find_refs(operation)
                for ref in all_refs:
                    target_name = ref.split('/')[-1]
                    if '#/components/schemas/' in ref:
                        edges_to_schemas.add((path_node_name, target_name))
                    elif '#/components/responses/' in ref:
                        edges_to_responses.add((path_node_name, target_name))

        endpoint_label = f"Endpoints - {tag}"

        all_edges = edges_to_schemas.union(edges_to_responses).union(edges_to_security)
        
        if all_edges:
            schema_nodes = {edge[1] for edge in edges_to_schemas}
            response_nodes = {edge[1] for edge in edges_to_responses}
            security_nodes = {edge[1] for edge in edges_to_security}
            
            target_groups = {
                "Schemas": schema_nodes,
                "Responses": response_nodes,
                "Security": security_nodes
            }
            
            output_path = os.path.join(output_dir, f'{tag}_dependencies.dot')
            generate_dot_file(output_path, source_nodes, endpoint_label, target_groups, all_edges, dark_mode)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python graph_generator.py <path_to_openapi_spec> [--dark]")
        sys.exit(1)
    
    dark_mode_enabled = "--dark" in sys.argv
    main(sys.argv[1], dark_mode=dark_mode_enabled)
