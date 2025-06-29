#!/usr/bin/env python3
"""
Universal Downloader for ComfyUI Models and Nodes
Supports configuration-driven downloads with smart path resolution
"""

import os
import sys
import json
import subprocess
import urllib.request
import shutil
from pathlib import Path
from urllib.parse import urlparse
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(message)s')
logger = logging.getLogger(__name__)


class UniversalDownloader:
    """Unified downloader for models and custom nodes"""
    
    def __init__(self, environment: str, comfyui_path: str = None, shared_models_path: str = None):
        self.environment = environment
        # Use environment-specific path if no custom path provided
        if comfyui_path:
            self.comfyui_path = Path(comfyui_path)
        elif environment == "comm":
            self.comfyui_path = Path("/workspace/ComfyUI")
        else:
            self.comfyui_path = Path(f"/workspace/ComfyUI-{environment}")
        self.shared_models_path = Path(shared_models_path) if shared_models_path else Path("/workspace/shared-models")
        self.config = None
        
    def load_config(self) -> dict:
        """Load environment configuration"""
        config_file = Path(__file__).parent.parent / "config" / "environments" / f"{self.environment}.json"
        
        if not config_file.exists():
            logger.error(f"Configuration file not found: {config_file}")
            return {}
            
        try:
            with open(config_file, 'r', encoding='utf-8') as f:
                self.config = json.load(f)
                logger.info(f"Loaded configuration for {self.environment}")
                return self.config
        except Exception as e:
            logger.error(f"Failed to load configuration: {e}")
            return {}
    
    def ensure_directory(self, path: Path) -> None:
        """Ensure directory exists"""
        path.parent.mkdir(parents=True, exist_ok=True)
    
    def download_file(self, url: str, target_path: Path) -> bool:
        """Download file with progress indication"""
        self.ensure_directory(target_path)
        
        if target_path.exists():
            logger.info(f"✓ Already exists: {target_path.name}")
            return True
            
        logger.info(f"→ Downloading: {target_path.name}")
        logger.info(f"  From: {url}")
        logger.info(f"  To: {target_path}")
        
        try:
            # Use curl for better compatibility and progress
            result = subprocess.run([
                'curl', '-L', '-o', str(target_path), url
            ], check=True, capture_output=True, text=True)
            
            if target_path.exists() and target_path.stat().st_size > 0:
                logger.info(f"✓ Downloaded: {target_path.name}")
                return True
            else:
                logger.error(f"✗ Download failed: {target_path.name}")
                if target_path.exists():
                    target_path.unlink()
                return False
                
        except subprocess.CalledProcessError as e:
            logger.error(f"✗ Download failed: {e}")
            if target_path.exists():
                target_path.unlink()
            return False
    
    def clone_repository(self, repo_url: str, target_dir: Path) -> bool:
        """Clone git repository"""
        if target_dir.exists():
            logger.info(f"✓ Already exists: {target_dir.name}")
            return True
            
        logger.info(f"→ Cloning: {target_dir.name}")
        logger.info(f"  From: {repo_url}")
        logger.info(f"  To: {target_dir}")
        
        try:
            result = subprocess.run([
                'git', 'clone', repo_url, str(target_dir)
            ], check=True, capture_output=True, text=True)
            
            logger.info(f"✓ Cloned: {target_dir.name}")
            return True
            
        except subprocess.CalledProcessError as e:
            logger.error(f"✗ Clone failed: {e}")
            if target_dir.exists():
                shutil.rmtree(target_dir)
            return False
    
    def install_node_requirements(self, node_dir: Path) -> bool:
        """Install node requirements if requirements.txt exists"""
        requirements_file = node_dir / "requirements.txt"
        if not requirements_file.exists():
            return True
            
        logger.info(f"→ Installing requirements for {node_dir.name}")
        
        try:
            # Change to the node directory and install requirements
            result = subprocess.run([
                'pip3', 'install', '-r', 'requirements.txt'
            ], cwd=node_dir, check=True, capture_output=True, text=True)
            
            logger.info(f"✓ Requirements installed for {node_dir.name}")
            return True
            
        except subprocess.CalledProcessError as e:
            logger.error(f"✗ Requirements installation failed for {node_dir.name}")
            logger.warning(f"  Node may still be functional, continuing...")
            # 只警告，不阻止整体安装
            return True
    
    def resolve_github_url(self, node_spec: str) -> str:
        """Resolve node specification to GitHub URL"""
        if node_spec.startswith('http'):
            return node_spec
        
        # Handle format: "username/repository"
        if '/' in node_spec:
            return f"https://github.com/{node_spec}.git"
        
        logger.error(f"Invalid node specification: {node_spec}")
        return ""
    
    def resolve_node_name(self, node_spec: str) -> str:
        """Extract node name from specification"""
        if '/' in node_spec:
            return node_spec.split('/')[-1]
        return node_spec
    
    def infer_model_type(self, url: str, filename: str = None) -> str:
        """Infer model type from URL or filename"""
        if not filename:
            filename = urlparse(url).path.split('/')[-1]
        
        filename_lower = filename.lower()
        
        # Model type mapping
        if any(keyword in filename_lower for keyword in ['checkpoint', 'ckpt']):
            return 'checkpoints'
        elif any(keyword in filename_lower for keyword in ['lora', 'lycoris']):
            return 'loras'
        elif any(keyword in filename_lower for keyword in ['controlnet', 'control']):
            return 'controlnet'
        elif any(keyword in filename_lower for keyword in ['vae']):
            return 'vae'
        elif any(keyword in filename_lower for keyword in ['clip', 'vision']):
            return 'clip_vision'
        elif any(keyword in filename_lower for keyword in ['ipadapter', 'ip-adapter']):
            return 'ipadapter'
        elif any(keyword in filename_lower for keyword in ['instantid']):
            return 'instantid'
        elif any(keyword in filename_lower for keyword in ['insightface', 'face']):
            return 'insightface'
        else:
            # Default to checkpoints for unknown types
            return 'checkpoints'
    
    def download_models(self) -> bool:
        """Download all models specified in configuration"""
        if not self.config or 'models' not in self.config:
            logger.info("No models to download")
            return True
        
        logger.info("=== Downloading Models ===")
        success_count = 0
        total_count = len(self.config['models'])
        
        for model_config in self.config['models']:
            if isinstance(model_config, str):
                # Simple URL format
                url = model_config
                filename = urlparse(url).path.split('/')[-1]
                model_type = self.infer_model_type(url, filename)
                target_path = self.shared_models_path / model_type / filename
            else:
                # Detailed configuration
                url = model_config['url']
                if 'path' in model_config:
                    target_path = self.shared_models_path / model_config['path']
                else:
                    filename = model_config.get('filename') or urlparse(url).path.split('/')[-1]
                    model_type = model_config.get('type') or self.infer_model_type(url, filename)
                    target_path = self.shared_models_path / model_type / filename
            
            if self.download_file(url, target_path):
                success_count += 1
        
        logger.info(f"Models: {success_count}/{total_count} downloaded successfully")
        return success_count == total_count
    
    def download_nodes(self) -> bool:
        """Download and install all nodes specified in configuration"""
        if not self.config or 'nodes' not in self.config:
            logger.info("No nodes to download")
            return True
        
        logger.info("=== Downloading Custom Nodes ===")
        success_count = 0
        total_count = len(self.config['nodes'])
        
        custom_nodes_dir = self.comfyui_path / "custom_nodes"
        
        for node_spec in self.config['nodes']:
            repo_url = self.resolve_github_url(node_spec)
            if not repo_url:
                continue
                
            node_name = self.resolve_node_name(node_spec)
            target_dir = custom_nodes_dir / node_name
            
            # Clone repository
            clone_success = self.clone_repository(repo_url, target_dir)
            if not clone_success:
                continue
            
            # Install requirements if they exist
            requirements_success = self.install_node_requirements(target_dir)
            
            # Only count as success if both clone and requirements succeed
            if clone_success and requirements_success:
                success_count += 1
        
        logger.info(f"Nodes: {success_count}/{total_count} completed successfully")
        return success_count == total_count
    
    
    def download_all(self) -> bool:
        """Download everything for the environment"""
        if not self.load_config():
            return False
        
        logger.info(f"=== Universal Downloader for {self.environment} ===")
        
        # Download models
        models_success = self.download_models()
        
        # Download nodes
        nodes_success = self.download_nodes()
        
        success = models_success and nodes_success
        
        if success:
            logger.info(f"✓ All downloads completed successfully for {self.environment}")
        else:
            logger.error(f"✗ Some downloads failed for {self.environment}")
        
        return success


def main():
    """Main entry point"""
    if len(sys.argv) < 2:
        logger.error("Environment name required")
        print(f"Usage: {sys.argv[0]} <environment>")
        print("Examples:")
        print(f"  {sys.argv[0]} comm")
        print(f"  {sys.argv[0]} aua-us")
        print(f"  {sys.argv[0]} aua-sp")
        sys.exit(1)
    
    environment = sys.argv[1]
    
    # Support custom paths via environment variables
    comfyui_path = os.getenv('COMFYUI_PATH')
    shared_models_path = os.getenv('SHARED_MODELS_PATH')
    
    downloader = UniversalDownloader(
        environment=environment,
        comfyui_path=comfyui_path,
        shared_models_path=shared_models_path
    )
    
    success = downloader.download_all()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()