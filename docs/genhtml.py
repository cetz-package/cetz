#!/usr/bin/env python3

import json
import sys
import os
import re
import subprocess
import tempfile
import argparse
from pathlib import Path


DEFAULT_CETZ_VERSION="@preview/cetz:0.4.2"

def typst_template(code, cetz_path):
  """Return full typst code for a cetz docstring example."""
  return f"""
#import "{cetz_path}" as cetz: *
#set page(width: auto, height: auto, margin: 0.5cm)
#cetz.canvas({{ import cetz.draw: * \n {code} \n }})
  """


def generate_output_from_typst(code, output_path, format="svg", cetz_path=DEFAULT_CETZ_VERSION):
    """Generate output from Typst code using the typst process."""
    try:
        with tempfile.NamedTemporaryFile(mode='w', suffix='.typ', delete=True) as tmp:
            tmp.write(typst_template(code, cetz_path))
            tmp.flush()
            result = subprocess.run(
                ["typst", "compile", tmp.name, str(output_path),
                 "--format", format],
                capture_output=True,
                text=True)

        if result.returncode != 0:
            print(f"Error generating {format.upper()}: {result.stderr}")
            return False
        
        return True
    except Exception as e:
        print(f"Exception generating {format.upper()}: {e}")
        return False


def convert_typst_to_html_content(text):
    """Convert Typst text to HTML content (just the body content)."""
    try:
        with tempfile.NamedTemporaryFile(mode='w', suffix='.typ', delete=True) as tmp:
            # Write the documentation text as Typst content
            typst_content = f"""
#set document(title: "Documentation")
#set text(font: "New Computer Modern")
#set par(justify: true)

{text}
"""
            tmp.write(typst_content)
            tmp.flush()
            
            with tempfile.NamedTemporaryFile(suffix='.html', delete=True) as html_tmp:
                result = subprocess.run(
                    ["typst", "compile", tmp.name, html_tmp.name,
                     "--format", "html", "--features", "html"],
                    capture_output=True,
                    text=True)

                if result.returncode != 0:
                    print(f"Error generating HTML: {result.stderr}")
                    return None
                
                # Read the generated HTML and extract body content
                with open(html_tmp.name, 'r') as f:
                    html_content = f.read()
                    
                # Extract content between <body> tags
                import re
                body_match = re.search(r'<body[^>]*>(.*?)</body>', html_content, re.DOTALL)
                if body_match:
                    return body_match.group(1).strip()
                else:
                    return html_content
        
    except Exception as e:
        print(f"Exception converting Typst to HTML: {e}")
        return None


def html_to_mdx(html_content):
    """Convert HTML content to MDX-compatible format."""
    if not html_content:
        return ""
    
    # Clean up the HTML for MDX compatibility
    # Remove any style attributes
    html_content = re.sub(r'\s+style="[^"]*"', '', html_content)
    
    # Convert some common HTML elements to JSX-friendly format
    # Self-closing tags need to be properly closed
    html_content = re.sub(r'<br>', '<br />', html_content)
    html_content = re.sub(r'<hr>', '<hr />', html_content)
    
    return html_content.strip()


def format_types(types_list):
    """Format a list of types into a comma-separated string."""
    if not types_list:
        return ""
    return ",".join(types_list)


def escape_json_string(text):
    """Escape a string for JSON."""
    if not text:
        return ""
    return text.replace('"', '\\"').replace('\n', '\\n').replace('\r', '\\r')


def generate_mdx_file(func_data, output_path, cetz_path=DEFAULT_CETZ_VERSION):
    """Generate an MDX file for a function matching generate-api.js format."""
    comment = func_data.get("comment", {})
    signature = func_data.get("signature", {})
    func_name = signature.get("name", "unknown")
    
    # Start MDX content
    mdx_lines = []
    
    # Build parameters object for Function component
    parameters = {}
    arguments = comment.get("arguments", [])
    for arg in arguments:
        name = arg.get("name", "")
        if name:
            param_info = {"types": format_types(arg.get("types", []))}
            default_value = arg.get("default-value", "")
            if default_value and default_value != "null":
                if default_value.startswith("= "):
                    default_value = default_value[2:]
                param_info["default"] = default_value
            parameters[name] = param_info
    
    # Function component (self-closing, no imports needed)
    import json
    parameters_json = json.dumps(parameters)
    mdx_lines.append(f'<Function name="{func_name}" parameters={{{parameters_json}}}/>'.replace('null', 'undefined'))
    
    # Convert main text through Typst -> HTML -> MDX
    main_text = comment.get("text", "")
    if main_text:
        # Remove example blocks from main text for separate processing
        text_without_examples = re.sub(r'```(?:typc?\s+)?(?:example|example-vertical)\s*\n.*?```', '', main_text, flags=re.DOTALL)
        
        html_content = convert_typst_to_html_content(text_without_examples)
        if html_content:
            mdx_content = html_to_mdx(html_content)
            mdx_lines.append(mdx_content)
            mdx_lines.append('')
    
    # Add example blocks
    examples = extract_example_blocks(main_text)
    if examples:
        for example_code in examples:
            mdx_lines.append('```typc example')
            mdx_lines.append(example_code)
            mdx_lines.append('```')
            mdx_lines.append('')
    
    # Add parameter documentation
    if arguments:
        for arg in arguments:
            name = arg.get("name", "")
            types = format_types(arg.get("types", []))
            default_value = arg.get("default-value", "")
            text = arg.get("text", "")
            
            if name:
                param_attrs = [f'name="{name}"']
                if types:
                    param_attrs.append(f'types="{types}"')
                if default_value and default_value != "null":
                    if default_value.startswith("= "):
                        default_value = default_value[2:]
                    param_attrs.append(f'default_value="{default_value}"')
                
                mdx_lines.append(f'<Parameter {" ".join(param_attrs)}>')
                
                if text:
                    # Convert parameter description through Typst -> HTML -> MDX
                    html_content = convert_typst_to_html_content(text)
                    if html_content:
                        mdx_content = html_to_mdx(html_content)
                        mdx_lines.append(mdx_content)
                
                mdx_lines.append('</Parameter>')
                mdx_lines.append('')
    
    # Write MDX file
    try:
        with open(output_path, 'w') as f:
            f.write('\n'.join(mdx_lines))
        return True
    except Exception as e:
        print(f"Error writing MDX file: {e}")
        return False


def extract_example_blocks(text):
    """Extract all example code blocks from text."""
    if not text:
        return []
    
    # Find all ```example or ```example-vertical blocks
    pattern = r'```(?:typc?\s+)?(?:example|example-vertical)\s*\n(.*?)```'
    matches = re.findall(pattern, text, re.DOTALL)
    
    return [match.strip() for match in matches]


def main():
    """Main function to process docs.json and generate MDX files with optional SVG examples."""
    # Set up argument parser
    parser = argparse.ArgumentParser(
        description='Generate MDX documentation from CeTZ docs with optional SVG examples'
    )
    parser.add_argument(
        'json_file', 
        nargs='?',
        help='Path to docs.json file (reads from stdin if not provided)'
    )
    parser.add_argument(
        '-o', '--output',
        type=str,
        default='mdx_output',
        help='Output directory for MDX files (default: mdx_output)'
    )
    parser.add_argument(
        '-c', '--cetz',
        type=str,
        default=DEFAULT_CETZ_VERSION,
        help=f'CeTZ package path (default: {DEFAULT_CETZ_VERSION}, use @local/cetz:VERSION for local)'
    )
    parser.add_argument(
        '--svg',
        nargs='?',
        const='svg_output',
        help='Generate SVG files from examples. Optional: specify output directory (default: svg_output)'
    )
    
    args = parser.parse_args()
    
    # Load JSON data
    if args.json_file:
        json_file = Path(args.json_file)
        if not json_file.exists():
            print(f"Error: {json_file} not found")
            sys.exit(1)
        
        with open(json_file, 'r') as f:
            data = json.load(f)
    else:
        # Try to read from stdin
        try:
            data = json.loads(sys.stdin.read())
        except:
            print("Error: Please provide docs.json as argument or via stdin")
            sys.exit(1)
    
    # Create output directory for MDX files (always generated)
    mdx_dir = Path(args.output)
    mdx_dir.mkdir(exist_ok=True)
    
    # Create SVG output directory if SVG generation is requested
    svg_dir = None
    if args.svg:
        svg_dir = Path(args.svg)
        svg_dir.mkdir(exist_ok=True)
    
    print(f"Using CeTZ package: {args.cetz}")
    print(f"MDX output directory: {mdx_dir}")
    if svg_dir:
        print(f"SVG output directory: {svg_dir}")
    
    # Data is actually a list with a single dict element
    if isinstance(data, list) and len(data) > 0:
        data = data[0]
    
    # Process each file in the JSON
    for file_path, functions in data.items():
        print(f"\nProcessing {file_path}")
        
        # Create directory structure matching source
        # e.g., "src/draw/shapes.typ" -> "draw/shapes/"
        path_parts = file_path.replace("src/", "").replace(".typ", "").split("/")
        
        # Create subdirectories for MDX files
        current_mdx_dir = mdx_dir
        for part in path_parts:
            current_mdx_dir = current_mdx_dir / part
            current_mdx_dir.mkdir(exist_ok=True)
        
        # Create subdirectories for SVG files if needed
        file_base = file_path.replace("src/", "").replace("/", "_").replace(".typ", "")
        
        # Track functions for combined file generation
        function_names = []
        
        # Process each function in the file
        for func_data in functions:
            signature = func_data.get("signature", {})
            func_name = signature.get("name", "unknown")
            comment = func_data.get("comment", {})
            text = comment.get("text", "")
            
            # Skip private functions (starting with _) for combined files
            if not func_name.startswith("_"):
                function_names.append(func_name)
            
            # Generate MDX documentation (always)
            mdx_filename = f"{func_name}.mdx"
            mdx_path = current_mdx_dir / mdx_filename
            
            if generate_mdx_file(func_data, mdx_path, args.cetz):
                print(f"[   OK] Generated MDX: {'/'.join(path_parts)}/{mdx_filename}")
            else:
                print(f"[ERROR] Failed to generate MDX: {'/'.join(path_parts)}/{mdx_filename}")
            
            # Generate SVG examples if requested
            if svg_dir:
                examples = extract_example_blocks(text)
                
                if examples:
                    for i, example_code in enumerate(examples):
                        # Generate unique filename
                        svg_filename = f"{file_base}_{func_name}_{i}.svg"
                        svg_path = svg_dir / svg_filename
                        
                        # Generate SVG
                        if generate_output_from_typst(example_code, svg_path, "svg", args.cetz):
                            print(f"[   OK] Generated SVG: {svg_filename} ({i+1}/{len(examples)})")
                        else:
                            print(f"[ERROR] Failed to generate SVG: {svg_filename}")
        
        # Generate combined MDX file
        if function_names:
            combined_filename = f"{path_parts[-1]}-combined.mdx"
            combined_path = current_mdx_dir / combined_filename
            
            combined_lines = []
            for func_name in function_names:
                # Convert function name to import name (uppercase, no hyphens)
                import_name = func_name.replace("-", "").upper()
                combined_lines.append(f'export {{ default as {import_name} }} from "./{func_name}.mdx";')
            
            try:
                with open(combined_path, 'w') as f:
                    f.write('\n'.join(combined_lines) + '\n')
                print(f"[   OK] Generated combined: {'/'.join(path_parts)}/{combined_filename} ({len(function_names)} functions)")
            except Exception as e:
                print(f"[ERROR] Failed to generate combined: {e}")
        else:
            print(f"[INFO] No public functions found for {'/'.join(path_parts)}, skipping combined file")


if __name__ == "__main__":
    main()
