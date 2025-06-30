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
        config_file = Path(__file__).parent.parent / "config" / "environments" / self.environment / "config.json"
        
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
    
    def download_file(self, url: str, target_path: Path, model_config: dict = None) -> bool:
        """Download file with progress indication and configurable source"""
        self.ensure_directory(target_path)
        
        # 检查现有文件是否完整（大于1MB）
        if target_path.exists():
            file_size = target_path.stat().st_size
            if file_size > 1024 * 1024:  # > 1MB，认为是完整文件
                logger.info(f"✓ Already exists: {target_path.name} ({file_size/1024/1024:.1f}MB)")
                return True
            else:
                logger.warning(f"Found incomplete file, re-downloading: {target_path.name} ({file_size} bytes)")
                target_path.unlink()
            
        logger.info(f"→ Downloading: {target_path.name}")
        logger.info(f"  From: {url}")
        logger.info(f"  To: {target_path}")
        
        # 获取下载源配置
        source = "auto"
        if model_config:
            source = model_config.get("source", "auto")
        
        try:
            return self._download_with_source(url, target_path, source, model_config)
        except Exception as e:
            logger.error(f"✗ Download failed: {e}")
            if target_path.exists():
                target_path.unlink()
            return False
    
    def _download_with_source(self, url: str, target_path: Path, source: str, model_config: dict) -> bool:
        """根据配置的源进行下载"""
        logger.info(f"  Using download source: {source}")
        
        if source == "auto":
            # 自动检测下载源
            if "huggingface.co" in url:
                return self._download_from_huggingface(url, target_path, model_config)
            elif "civitai.com" in url:
                return self._download_from_civitai(url, target_path, model_config)
            else:
                return self._download_with_curl(url, target_path, model_config)
        
        elif source == "huggingface-cli":
            return self._download_from_huggingface(url, target_path, model_config)
        
        elif source == "civitai":
            return self._download_from_civitai(url, target_path, model_config)
        
        elif source == "curl":
            return self._download_with_curl(url, target_path, model_config)
        
        else:
            logger.error(f"Unsupported download source: {source}")
            return False
    
    def _download_from_huggingface(self, url: str, target_path: Path, model_config: dict = None) -> bool:
        """Download from Hugging Face using Python API with curl fallback"""
        try:
            # 尝试使用 huggingface_hub Python API
            try:
                from huggingface_hub import hf_hub_download
                logger.info("Using huggingface_hub Python API")
            except ImportError:
                logger.warning("huggingface_hub not available, falling back to curl")
                return self._download_with_curl(url, target_path, model_config)
            
            # 解析 Hugging Face URL
            # URL格式: https://huggingface.co/user/repo/resolve/main/file.safetensors
            parts = url.split('/')
            if len(parts) < 6:
                raise ValueError(f"Invalid Hugging Face URL format: {url}")
            
            repo_id = f"{parts[3]}/{parts[4]}"  # user/repo
            filename = parts[-1]  # file.safetensors
            
            # 获取 repo_type，默认为 "model"
            repo_type = "model"
            if model_config:
                # 新格式：download_params.repo_type
                if model_config.get("download_params") and model_config["download_params"].get("repo_type"):
                    repo_type = model_config["download_params"]["repo_type"]
                # 兼容旧格式：直接的 repo_type
                elif model_config.get("repo_type"):
                    repo_type = model_config["repo_type"]
            
            logger.info(f"Downloading from repo: {repo_id}, file: {filename}, repo_type: {repo_type}")
            
            # 使用 huggingface_hub 下载
            downloaded_path = hf_hub_download(
                repo_id=repo_id,
                filename=filename,
                repo_type=repo_type,
                local_dir=str(target_path.parent),
                local_dir_use_symlinks=False
            )
            
            # 验证下载结果
            if target_path.exists():
                file_size = target_path.stat().st_size
                if file_size > 1024:  # 至少1KB
                    logger.info(f"✓ Downloaded: {target_path.name} ({file_size/1024/1024:.1f}MB)")
                    return True
                else:
                    logger.error(f"✗ Downloaded file too small: {target_path.name} ({file_size} bytes)")
                    target_path.unlink()
                    return False
            else:
                logger.error(f"✗ File not found after download: {target_path}")
                return False
                
        except Exception as e:
            logger.error(f"✗ Hugging Face API download failed: {e}")
            logger.warning("Falling back to curl download")
            return self._download_with_curl(url, target_path, model_config)
    
    def _download_with_curl(self, url: str, target_path: Path, model_config: dict = None) -> bool:
        """Download with curl as fallback"""
        try:
            # 使用更强健的 curl 参数
            result = subprocess.run([
                'curl', '-L', '-f', '--fail-with-body', '--progress-bar',
                '-o', str(target_path), url
            ], check=True, capture_output=True, text=True)
            
            # 验证下载结果
            if target_path.exists():
                file_size = target_path.stat().st_size
                if file_size > 1024:  # 至少1KB
                    logger.info(f"✓ Downloaded: {target_path.name} ({file_size/1024/1024:.1f}MB)")
                    return True
                else:
                    logger.error(f"✗ Downloaded file too small: {target_path.name} ({file_size} bytes)")
                    target_path.unlink()
                    return False
            else:
                logger.error(f"✗ File not found after download: {target_path}")
                return False
                
        except subprocess.CalledProcessError as e:
            logger.error(f"✗ curl download failed: {e}")
            return False
    
    def _download_from_civitai(self, url: str, target_path: Path, model_config: dict = None) -> bool:
        """Download from Civitai with API token support"""
        try:
            # 构建 curl 命令
            curl_cmd = ['curl', '-L', '-f', '--fail-with-body', '--progress-bar']
            
            # 添加 API token（如果配置了）
            if model_config and model_config.get("api_token"):
                curl_cmd.extend(['-H', f'Authorization: Bearer {model_config["api_token"]}'])
            
            # 添加自定义 headers（如果配置了）
            if model_config and model_config.get("headers"):
                for key, value in model_config["headers"].items():
                    curl_cmd.extend(['-H', f'{key}: {value}'])
            
            curl_cmd.extend(['-o', str(target_path), url])
            
            result = subprocess.run(curl_cmd, check=True, capture_output=True, text=True)
            
            # 验证下载结果
            if target_path.exists():
                file_size = target_path.stat().st_size
                if file_size > 1024:  # 至少1KB
                    logger.info(f"✓ Downloaded: {target_path.name} ({file_size/1024/1024:.1f}MB)")
                    return True
                else:
                    logger.error(f"✗ Downloaded file too small: {target_path.name} ({file_size} bytes)")
                    target_path.unlink()
                    return False
            else:
                logger.error(f"✗ File not found after download: {target_path}")
                return False
                
        except subprocess.CalledProcessError as e:
            logger.error(f"✗ Civitai download failed: {e}")
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
        
        # 确定环境目录和虚拟环境路径
        env_dir = self.comfyui_path  # 使用当前环境的 ComfyUI 路径
        venv_pip = env_dir / "venv" / "bin" / "pip"
        
        if not venv_pip.exists():
            logger.error(f"Virtual environment pip not found: {venv_pip}")
            logger.warning(f"  Falling back to system pip for {node_dir.name}")
            # 继续使用系统 pip，不阻止整体安装
            pip_cmd = 'pip3'
            env_vars = None
        else:
            logger.debug(f"Using virtual environment pip: {venv_pip}")
            pip_cmd = str(venv_pip)
            # 设置虚拟环境变量
            env_vars = os.environ.copy()
            env_vars['VIRTUAL_ENV'] = str(env_dir / "venv")
            env_vars['PATH'] = f"{env_dir / 'venv' / 'bin'}:{env_vars.get('PATH', '')}"
        
        try:
            # 使用正确的 pip 安装依赖
            result = subprocess.run([
                pip_cmd, 'install', '-r', 'requirements.txt'
            ], cwd=node_dir, check=True, capture_output=True, text=True, env=env_vars)
            
            logger.info(f"✓ Requirements installed for {node_dir.name}")
            return True
            
        except subprocess.CalledProcessError as e:
            logger.error(f"✗ Requirements installation failed for {node_dir.name}")
            logger.warning(f"  Error: {e.stderr if e.stderr else str(e)}")
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
            
            if self.download_file(url, target_path, model_config):
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