#!/usr/bin/env python3

import json
import sys
import os
import re
import subprocess
import tempfile
import argparse
from pathlib import Path


DEFAULT_CETZ_VERSION="@preview/cetz:0.5.0"


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
//#set text(font: "New Computer Modern")
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

    # Clean up the HTML for MDX compatibility:
    # - Remove style attributes
    # - Convert self closing to closing
    html_content = re.sub(r'\s+style="[^"]*"', '', html_content)
    html_content = re.sub(r'<br>', '<br />', html_content)
    html_content = re.sub(r'<hr>', '<hr />', html_content)

    return html_content.strip()


def format_types(types_list):
    """Format a list of types into a comma-separated string."""
    if not types_list:
        return ""
    return ",".join(types_list)


def escape_html_attr(text):
    """Escape text for HTML attribute values."""
    if not text:
        return ""
    return (text.replace('&', '&amp;')
               .replace('"', '&quot;')
               .replace("'", '&#39;')
               .replace('<', '&lt;')
               .replace('>', '&gt;'))


def generate_mdx_file(func_data, output_path, cetz_path=DEFAULT_CETZ_VERSION):
    """Generate an MDX file for a function."""
    comment = func_data.get("comment", {})
    signature = func_data.get("signature", {})
    func_name = signature.get("name", "unknown") if signature else "unknown"

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

    # Function component
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
                    param_attrs.append(f'default_value="{escape_html_attr(default_value)}"')

                mdx_lines.append(f'<Parameter {" ".join(param_attrs)}>')

                if text:
                    # Convert parameter description through Typst -> HTML -> MDX
                    html_content = convert_typst_to_html_content(text)
                    if html_content:
                        mdx_content = html_to_mdx(html_content)
                        mdx_lines.append(mdx_content)

                mdx_lines.append('</Parameter>')
                mdx_lines.append('')

    try:
        with open(output_path, 'w') as f:
            f.write('\n'.join(mdx_lines))
        return True
    except Exception as e:
        print(f"Error writing MDX file: {e}")
        return False


def extract_example_blocks(text):
    """Extract all example code blocks from text with proper indentation."""
    if not text:
        return []

    # Find all ```example or ```example-vertical blocks
    pattern = r'```(?:typc?\s+)?(?:example|example-vertical)\s*\n(.*?)```'
    matches = re.findall(pattern, text, re.DOTALL)

    cleaned_blocks = []
    for match in matches:
        lines = match.split('\n')
        if not lines:
            continue

        # Remove leading/trailing empty lines
        while lines and not lines[0].strip():
            lines.pop(0)
        while lines and not lines[-1].strip():
            lines.pop()

        if not lines:
            continue

        # Find the minimum indentation (excluding empty lines)
        min_indent = float('inf')
        for line in lines:
            if line.strip():  # Skip empty lines
                indent = len(line) - len(line.lstrip())
                min_indent = min(min_indent, indent)

        # Remove the common indentation from all lines
        if min_indent != float('inf') and min_indent > 0:
            dedented_lines = []
            for line in lines:
                if line.strip():  # Non-empty line
                    dedented_lines.append(line[min_indent:])
                else:  # Empty line
                    dedented_lines.append('')
            cleaned_blocks.append('\n'.join(dedented_lines))
        else:
            cleaned_blocks.append('\n'.join(lines))

    return cleaned_blocks


def main():
    """Main function to process docs.json and generate MDX files with optional SVG examples."""
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
            print(f"Error: {json_file} not found.")
            sys.exit(1)

        with open(json_file, 'r') as f:
            data = json.load(f)
    else:
        # If no filename is provided: read from stdin
        try:
            data = json.loads(sys.stdin.read())
        except:
            print("Error: Could not read from stdin.")
            sys.exit(1)

    mdx_dir = Path(args.output)
    mdx_dir.mkdir(exist_ok=True)
    svg_dir = None
    if args.svg:
        svg_dir = Path(args.svg)
        svg_dir.mkdir(exist_ok=True)

    if isinstance(data, list) and len(data) > 0:
        data = data[0]

    # Process each file in the JSON
    for file_path, functions in data.items():
        print(f"\nProcessing {file_path}")

        # Create directory structure matching source
        # e.g., "src/draw/shapes.typ" -> "draw/shapes/"
        path_parts = file_path.replace("src/", "").replace(".typ", "").split("/")

        current_mdx_dir = mdx_dir
        for part in path_parts:
            current_mdx_dir = current_mdx_dir / part
            current_mdx_dir.mkdir(exist_ok=True)

        file_base = file_path.replace("src/", "").replace("/", "_").replace(".typ", "")

        # Track functions for combined file generation
        function_names = []
        for func_data in functions:
            signature = func_data.get("signature", {})
            func_name = signature.get("name", "unknown") if signature else "unknown"
            comment = func_data.get("comment", {})
            text = comment.get("text", "")

            if not func_name.startswith("_"):
                function_names.append(func_name)

            # Generate MDX files
            mdx_filename = f"{func_name}.mdx"
            mdx_path = current_mdx_dir / mdx_filename

            if generate_mdx_file(func_data, mdx_path, args.cetz):
                print(f"[   OK] Generated MDX: {'/'.join(path_parts)}/{mdx_filename}")
            else:
                print(f"[ERROR] Failed to generate MDX: {'/'.join(path_parts)}/{mdx_filename}")

            # Generate SVGs
            if svg_dir:
                examples = extract_example_blocks(text)

                if examples:
                    for i, example_code in enumerate(examples):
                        svg_filename = f"{file_base}_{func_name}_{i}.svg"
                        svg_path = svg_dir / svg_filename

                        if generate_output_from_typst(example_code, svg_path, "svg", args.cetz):
                            print(f"[   OK] Generated SVG: {svg_filename} ({i+1}/{len(examples)})")
                        else:
                            print(f"[ERROR] Failed to generate SVG: {svg_filename}")

        # Generate combined MDX file
        if function_names:
            #combined_filename = f"{path_parts[-1]}-combined.mdx"
            combined_filename = f"-combined.mdx"
            combined_path = current_mdx_dir / combined_filename

            combined_imports = []
            combined_lines = []
            for func_name in function_names:
                import_name = func_name.replace("-", "").upper()
                combined_imports.append(f'import {import_name} from "./{func_name}.mdx"')
                combined_lines.append(f'## {func_name}')
                combined_lines.append(f'<{import_name}/>\n')

            try:
                with open(combined_path, 'w') as f:
                    f.write('\n'.join(combined_imports) + '\n\n' + '\n'.join(combined_lines) + '\n')
                print(f"[   OK] Generated combined: {'/'.join(path_parts)}/{combined_filename}")
            except Exception as e:
                print(f"[ERROR] Failed to generate combined: {e}")
        else:
            print(f"[ INFO] No public functions found for {'/'.join(path_parts)}, skipping combined file")


if __name__ == "__main__":
    main()
