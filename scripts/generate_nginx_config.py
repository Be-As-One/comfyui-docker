#!/usr/bin/env python3
"""
Generate dynamic nginx configuration for ComfyUI environments
Reads environment configurations and creates nginx proxy rules
"""

import json
import os
from pathlib import Path


def read_environment_configs(config_dir: str) -> dict:
    """Read all environment configuration files"""
    environments = {}
    config_path = Path(config_dir)
    
    if not config_path.exists():
        print(f"Config directory not found: {config_dir}")
        return environments
    
    for config_file in config_path.glob("*.json"):
        try:
            with open(config_file, 'r', encoding='utf-8') as f:
                config = json.load(f)
                env_name = config.get('name')
                env_port = config.get('port')
                
                if env_name and env_port:
                    environments[env_name] = env_port
                    print(f"Found environment: {env_name} -> port {env_port}")
                else:
                    print(f"Invalid config in {config_file}: missing name or port")
        except Exception as e:
            print(f"Error reading {config_file}: {e}")
    
    return environments


def generate_nginx_config(environments: dict, template_file: str, output_file: str) -> None:
    """Generate nginx configuration from template"""
    
    # Convert output_file to Path object
    output_path = Path(output_file)
    
    # Generate map entries for environment to port mapping
    map_entries = []
    for env_name, port in environments.items():
        map_entries.append(f'        "{env_name}" {port};')
    
    # Default environment (usually 'comm')
    default_env = 'comm'
    default_port = environments.get(default_env, 3001)
    
    # Generate specific location blocks for each environment
    location_blocks = []
    for env_name, port in environments.items():
        location_blocks.append(f"""
        # Route to {env_name} environment (port {port})
        location /{env_name}/ {{
            proxy_pass http://127.0.0.1:{port}/;
            proxy_http_version 1.1;
            proxy_set_header Accept-Encoding gzip;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            add_header Cache-Control no-cache;
            proxy_intercept_errors on;
            error_page 502 =200 @502;
        }}
        
        location = /{env_name} {{
            return 301 /{env_name}/;
        }}""")

    # Create nginx configuration content
    nginx_config = f"""events {{ worker_connections 2048; }}

http {{
    # Increase the max body size from the default of 1MB to 500MB
    client_max_body_size 500M;

    # Increase proxy timeout from 60s to 600s
    proxy_connect_timeout 600;
    proxy_send_timeout    600;
    proxy_read_timeout    600;
    send_timeout          600;
    
    # Enable gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    # ComfyUI Dynamic Router
    server {{
        listen 3000;
{''.join(location_blocks)}

        # Default route (no environment prefix)
        location / {{
            proxy_pass http://127.0.0.1:{default_port}/;
            proxy_http_version 1.1;
            proxy_set_header Accept-Encoding gzip;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            add_header Cache-Control no-cache;
            proxy_intercept_errors on;
            error_page 502 =200 @502;
        }}

        location @502 {{
            # kill cache
            add_header Last-Modified $date_gmt;
            add_header Cache-Control 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0';
            if_modified_since off;
            expires off;
            etag off;

            root /usr/share/nginx/html;
            rewrite ^(.*)$ /502.html break;
        }}
    }}
}}
"""

    # Write configuration to file
    try:
        # Ensure directory exists
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Check if file exists and permissions
        if output_path.exists():
            print(f"Overwriting existing config: {output_path}")
        else:
            print(f"Creating new config: {output_path}")
        
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(nginx_config)
        print(f"Generated nginx configuration: {output_path}")
        
        # Also print the environments found
        print("\\nEnvironments configured:")
        for env_name, port in environments.items():
            print(f"  - /{env_name} -> port {port}")
        print(f"  - / (default) -> port {default_port}")
        
    except Exception as e:
        print(f"Error writing nginx config: {e}")
        print(f"Output path: {output_path}")
        print(f"Parent directory exists: {output_path.parent.exists()}")
        print(f"Parent directory permissions: {oct(output_path.parent.stat().st_mode)[-3:] if output_path.parent.exists() else 'N/A'}")


def main():
    """Main entry point"""
    import sys
    
    # Get script directory
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    
    # Paths - adjust for container environment
    if os.path.exists("/config/environments"):
        # Running in container
        config_dir = Path("/config/environments")
        output_file = Path("/etc/nginx/nginx.conf")
    else:
        # Running in development
        config_dir = project_root / "config" / "environments"
        output_file = project_root / "nginx" / "nginx.conf"
    
    # Check for reload option
    reload_nginx = "--reload" in sys.argv
    
    print(f"Reading environment configs from: {config_dir}")
    print(f"Output nginx config to: {output_file}")
    
    # Read environment configurations
    environments = read_environment_configs(str(config_dir))
    
    if not environments:
        print("No valid environments found!")
        return
    
    # Generate nginx configuration
    generate_nginx_config(environments, "", str(output_file))
    
    # Optionally reload nginx
    if reload_nginx:
        print("Reloading nginx configuration...")
        try:
            import subprocess
            subprocess.run(['nginx', '-s', 'reload'], check=True)
            print("Nginx reloaded successfully")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("Failed to reload nginx (may not be running yet)")


if __name__ == "__main__":
    main()